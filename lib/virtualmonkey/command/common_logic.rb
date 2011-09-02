module VirtualMonkey
  module Command
    def self.load_config_file
      raise "--config_file is required!" unless @@options[:config_file]
      config = JSON::parse(IO.read(@@options[:config_file]))
      @@options[:prefix] += "-" if @@options[:prefix]
      @@options[:prefix] = "" unless @@options[:prefix]
      @@options[:prefix] += config['prefix']
      @@options[:common_inputs] = config['common_inputs'].map { |cipath| File.join(@@ci_dir, cipath) }
      @@options[:feature] = load_features(config)
      @@options[:runner] ||= get_runner_class
      @@options[:terminate] = true if @@command =~ /troop|destroy/
      @@options[:clouds] = load_clouds(config) unless @@options[:clouds] and @@options[:clouds].length > 0
      @@options[:server_template_ids] = config['server_template_ids']
    end

    def self.load_clouds(config)
      # TODO Multicloud Deployments
      return config['clouds'] if config['clouds']
      VirtualMonkey::Toolbox::get_available_clouds.map { |hsh| hsh["cloud_id"].to_i }
    end

    # Encapsulates the logic for selecting a subset of deployments
    def self.select_only_logic(message)
      @@do_these ||= @@dm.deployments
      @@do_these = @@do_these.select { |d| d.nickname =~ /#{@@options[:only]}/ } if @@options[:only]
      all_clouds = VirtualMonkey::Toolbox::get_available_clouds.map { |hsh| hsh["cloud_id"].to_i }
      (all_clouds - @@options[:clouds]).each { |cid|
        @@do_these.reject! { |d| d.nickname =~ /-cloud_#{cid}-/ }
      }
      unless @@options[:no_resume] or @@command =~ /destroy|audit/
        temp = @@do_these.select do |d|
          files_to_check = @@options[:feature] + [GrinderMonk.combo_feature_name(@@options[:feature])]
          files_to_check.any? { |feature|
            File.exist?(File.join(@@global_state_dir, d.nickname, File.basename(feature)))
          }
        end 
        @@do_these = temp if temp.length > 0 
      end 

      raise "No deployments matched!" unless @@do_these.length > 0 
      if @@options[:verbose]
        pp @@do_these.map { |d| { d.nickname => d.servers.map { |s| s.state } } }
      else
        pp @@do_these.map { |d| d.nickname }
      end
      unless @@options[:yes] or @@command == "troop"
        confirm = ask("#{message} these #{@@do_these.size} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) }) 
        raise "Aborting." unless confirm
      end   
    end

    # Encapsulates the logic for loading the necessary variables to create a set of deployments
    def self.create_logic
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      if @@options[:clouds]
        @@dm.load_clouds(@@options[:clouds])
#      elsif @@options[:cloud_variables]
#        @@options[:cloud_variables].each { |cvpath| @@dm.load_cloud_variables(cvpath) }
      else
        raise "Usage Error! Need --clouds"
      end
      @@options[:common_inputs].each { |cipath| @@dm.load_common_inputs(cipath) }
      @@dm.generate_variations(@@options)
    end

    # Encapsulates the logic for launching and monitoring a set of asynchronous processes that run grinder
    # with a test case. Included is the logic for optionally destroying "successful" servers or
    # running "successful" servers through the log auditor/trainer.
    def self.run_logic
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      @@options[:runner] ||= get_runner_class
      raise "FATAL: Could not determine runner class" unless @@options[:runner]

      EM.run {
        @@gm ||= GrinderMonk.new
        @@dm ||= DeploymentMonk.new(@@options[:prefix], [], [], @@options[:allow_meta_monkey])
        @@options[:runner] ||= get_runner_class
        select_only_logic("Run tests on")

        @@gm.options = @@options

        @@gm.run_tests(@@do_these, @@options[:feature], @@options[:tests])
        @@remaining_jobs = @@gm.jobs.dup

        watch = EM.add_periodic_timer(10) {
          begin
            @@gm.watch_and_report
            if @@gm.all_done?
              watch.cancel
            end
            
            if @@options[:terminate] and not (@@options[:list_trainer] or @@options[:qa])
              @@remaining_jobs.each do |job|
                if job.status == 0
                  destroy_job_logic(job)
                end
              end
            end
          rescue Interrupt
            exit(1)
          rescue Exception => e
            puts "WARNING: Got #{e.message} from #{e.backtrace.first}"
          end
        }
        if @@options[:list_trainer] or @@options[:qa]
          @@remaining_jobs.each do |job|
            if job.status == 0
              audit_log_deployment_logic(job.deployment, :interactive)
              destroy_job_logic(job) if @@options[:terminate]
            end
          end
        end
      }
    end

    # Encapsulates the logic for running through the log auditor/trainer on a single deployment
    def self.audit_log_deployment_logic(deployment, interactive = false)
      @@options[:runner] ||= get_runner_class
      raise "FATAL: Could not determine runner class" unless @@options[:runner]
      runner = @@options[:runner].new(deployment.nickname)
      puts runner.run_logger_audit(interactive, @@options[:qa])
    end

    # Encapsulates the logic for destroying the deployment from a single job
    def self.destroy_job_logic(job)
      @@options[:runner] ||= get_runner_class
      raise "FATAL: Could not determine runner class" unless @@options[:runner]
      runner = @@options[:runner].new(job.deployment.nickname)
      puts "Destroying successful deployment: #{runner.deployment.nickname}"
      runner.stop_all(false)
      #Release DNS logic
      if runner.respond_to?(:release_dns) and not @@options[:keep]
        release_all_dns_domains(runner.deployment.href)
      end
      if runner.respond_to?(:release_container) and not @@options[:keep]
        runner.release_container
      end
      runner.deployment.destroy unless @@options[:keep] or @@command =~ /run|clone/
      @@remaining_jobs.delete(job)
    end

    # Encapsulates the logic for destroying all matched deployments
    def self.destroy_all_logic
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      @@options[:runner] ||= get_runner_class
      raise "FATAL: Could not determine runner class" unless @@options[:runner]
      @@do_these ||= @@dm.deployments
      @@do_these.each do |deploy|
        runner = @@options[:runner].new(deploy.nickname)
        runner.stop_all(false)
        complete = false
        begin
          state_dir = File.join(@@global_state_dir, deploy.nickname)
          if File.directory?(state_dir)
            puts "Deleting state files for #{deploy.nickname}..."
            Dir.new(state_dir).each do |state_file|
              if File.extname(state_file) =~ /((rb)|(feature))/
                File.delete(File.join(state_dir, state_file))
              end 
            end 
            FileUtils.rm_rf(state_dir)
          end 
          #Release DNS logic
          if runner.respond_to?(:release_dns) and not @@options[:keep]
            release_all_dns_domains(deploy.href)
          end
          if runner.respond_to?(:release_container) and not @@options[:keep]
            runner.release_container
          end
          # Cleanup volumes and snapshots for runners that support it.
          if runner.respond_to?(:set_variation_lineage) and not @@options[:keep]
            runner.set_variation_lineage
          end
          if runner.respond_to?(:cleanup_volumes) and not @@options[:keep]
            runner.cleanup_volumes
          end
          if runner.respond_to?(:cleanup_snapshots) and not @@options[:keep]
            runner.cleanup_snapshots
          end
          complete = true
        rescue Interrupt
          exit(1)
        rescue Exception => e
          puts "WARNING: Got #{e.message} from #{e.backtrace.first}"
          sleep 5
        end while not complete
      end 

      @@dm.destroy_all unless @@options[:keep]
    end

    # Encapsulates the logic for releasing the DNS entries for a single deployment, no matter what DNS it used
    def self.release_all_dns_domains(deploy_href)
      ["virtualmonkey_shared_resources", "virtualmonkey_awsdns", "virtualmonkey_dyndns"].each { |domain|
        begin
          dns = SharedDns.new(domain)
          raise "Unable to reserve DNS" unless dns.reserve_dns(deploy_href)
          dns.release_dns
        rescue Exception => e
          raise e unless e.message =~ /Unable to reserve DNS/
        end
      }
    end

    # Encapsulates the logic for detecting what runner is used in a test case file
    def self.get_runner_class #returns class string
      return @@options[:runner] if @@options[:runner]
      features = [@@options[:feature]].flatten
      test_cases = features.map { |feature| VirtualMonkey::TestCase.new(feature) }
      unless test_cases.unanimous? { |tc| tc.options[:runner] }
        raise ":runner options MUST match for multiple feature files"
      end
      unless test_cases.unanimous? { |tc| tc.options[:allow_meta_monkey] }
        raise ":allow_meta_monkey options MUST match for multiple feature files"
      end
      return @@options[:runner] = test_cases.first.options[:runner]
    end

    def self.load_features(config)
      features = [config['feature']].flatten.map { |feature| File.join(@@features_dir, feature) }
      test_cases = features.map { |feature| VirtualMonkey::TestCase.new(feature) }
      unless test_cases.unanimous? { |tc| tc.options[:runner] }
        raise ":runner options MUST match for multiple feature files"
      end
      unless test_cases.unanimous? { |tc| tc.options[:allow_meta_monkey] }
        raise ":allow_meta_monkey options MUST match for multiple feature files"
      end
      @@options[:allow_meta_monkey] = test_cases.first.options[:allow_meta_monkey]
      @@options[:runner] = test_cases.first.options[:runner]
      @@options[:feature] = features
    end

    ##################################
    # Onboarding/File-Creation Logic #
    ##################################

    def self.build_scenario_names(underscore_name = " ")
      if underscore_name != " "
        if ask("Is \"#{underscore_name.gsub(/ /,"_")}\" an acceptable name for this scenario (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
          underscore_name.gsub!(/ /,"_")
        else
          underscore_name = " "
        end
      end

      while underscore_name.gsub!(/ /,"")
        underscore_name = ask("What is the name for this runner? (Please use underscores instead of spaces), eg. 'mysql', 'php_chef', etc.)")
      end
      @@underscore_name = underscore_name.downcase
      @@camel_case_name = @@underscore_name.camelcase
      @@common_inputs_file = File.join(@@ci_dir, "#{@@underscore_name}.json")
      @@feature_file = File.join(@@features_dir, "#{@@underscore_name}.rb")
      @@mixin_file = File.join(@@mixin_dir, "#{@@underscore_name}.rb")
      @@runner_file = File.join(@@runner_dir, "#{@@underscore_name}_runner.rb")
      @@troop_file = File.join(@@troop_dir, "#{@@underscore_name}.json")

      @@script_table = []
    end

    def self.build_script_array(st_ary)
      st_ary.uniq_by { |st| st.href }.each { |st|
        script_array = []
        op_execs = st.executables.select { |rs| rs.apply == "operational" }
        op_exec_names = op_execs.map { |rs| rs.recipe ? rs.recipe : rs.right_script["name"] }
        op_exec_names.each { |rs_name|
          @@script_table << [(@@script_table.length + 1), rs_name, st]
        }
      }
    end

    def self.build_troop_config(deployment = nil)
      @@troop_config = {}
      @@troop_config[:prefix] = "#{@@underscore_name.upcase}_TROOP"

      if deployment
        # Model Deployment Given
        st_ary = []
        deployment.servers_no_reload.each { |s|
          st_ary << ServerTemplate.find(s.server_template_href)
        }
        @@troop_config[:server_templates_ids] = st_ary.map { |st| st.rs_id.to_s }
      else
        # Interactively Build
        correct = false
        until correct
          st_ary = []
          @@troop_config[:server_template_ids] = ask("What Server Template ids would you like to use to create the deployments (comma delimited)?").split(",")
          @@troop_config[:server_template_ids].each { |st|
            st.strip!
            st_ary << ServerTemplate.find(st.to_i)
          }
          puts st_ary.map { |st| st.nickname }.join("\n")
          correct = ask("Are these the ServerTemplates that you wish to use with this runner? (y/n)", lambda { |ans| true if (ans =~ /^[yY]{1}/) })
        end

        puts "Available Clouds for this Account (Note that your MCI's may not support all of these):"
        VirtualMonkey::Toolbox::get_available_clouds().each { |cloud| puts "#{cloud['cloud_id']}: #{cloud['name']}" }
        list_of_clouds = ask("Enter a comma-delimited list of cloud_ids to use:").split(",")
        @@troop_config[:clouds] = list_of_clouds.map { |c| c.to_i }
      end

      build_script_array(st_ary)
      @@st_ary = st_ary

      @@troop_config[:common_inputs] = File.basename(@@common_inputs_file)
      @@troop_config[:feature] = File.basename(@@feature_file)
    end

    def self.write_common_inputs_file(input_hash={"EXAMPLE_INPUT" => "text:value"})
      say("Creating example common inputs file...")
      write_out = input_hash.to_json( :indent => "  ",
                                      :object_nl => "\n",
                                      :array_nl => "\n" )
      File.open(@@common_inputs_file, "w") { |f| f.write(write_out) }
    end

    def self.write_feature_file
      say("Creating feature file...")
      contents =<<EOS
set :runner, VirtualMonkey::Runner::#{@@camel_case_name}

hard_reset do
  stop_all
end

before do
  launch_all
  wait_for_all("operational")
end

test "check_monitoring" do
  check_monitoring
end
EOS
      # Add Script Tests
      @@script_table.each { |index,script,st|
        contents +=<<EOS
###{"#" * script.length}##
# #{script} #
###{"#" * script.length}##

before "script_#{index}" do
end

test "script_#{index}" do
  run_script_on_set("script_#{index}", server_templates.detect { |st| st.name =~ /#{st.nickname}/ }, true, {})
end

after "script_#{index}" do
end

EOS
      }
      contents +=<<EOS
after do
  # Cleanup
end
EOS
      File.open(@@feature_file, "w") { |f| f.write(contents) }
    end

    def self.write_troop_file
      say("Creating troop config...")
      write_out = @@troop_config.to_json( :indent => "  ",
                                          :object_nl => "\n",
                                          :array_nl => "\n" )
      File.open(@@troop_file, "w") { |f| f.write(write_out) }
    end

    def self.write_mixin_file
      say("Creating mixin file...")
      mixin_tpl =<<EOS
module VirtualMonkey
  module Mixin
    module #{@@camel_case_name}
EOS
      # Lookup Scripts
      mixin_tpl += <<EOS
      # Every instance method included in the runner class that has
      # "lookup_scripts" in its name is called when the Class is instantiated.
      # These functions help to create a hash table of RightScripts and/or
      # Chef Recipes that can be called on a given Server in the deployment.
      # By default, the functions that are used to create this hash table
      # allow every referenced Executable to be run on every server in the
      # deployment, but they can be restricted to only certain ServerTemplates
      # in the deployment.
      def #{@@underscore_name}_lookup_scripts
EOS
      st_ary = @@script_table.map { |index,script,st| st }.uniq_by { |st| st.href }
      st_ary.each { |st_ref|
        st_script_table = @@script_table.select { |index,script,st| st.href == st_ref.href }
        st_ver = (st_ref.is_head_version ? "[HEAD]" : "[rev #{st_ref.version}]")
        comment_string = "# Load Scripts from '#{st_ref.nickname}' #{st_ver} #"
        mixin_tpl += "        #{"#" * comment_string.length}\n"
        mixin_tpl += "        #{comment_string}\n"
        mixin_tpl += "        #{"#" * comment_string.length}\n"
        mixin_tpl += "        scripts = [\n"
        script_array = st_script_table.map { |index,script,st| "                   ['script_#{index}', '#{Regexp.escape(script)}']" }
        mixin_tpl += "#{script_array.join(",\n")}\n"
        mixin_tpl += "                  ]\n"
        mixin_tpl += "        st_ref = @server_templates.detect { |st| st.rs_id.to_i == #{st_ref.rs_id.to_i} }\n"
        mixin_tpl += "        load_script_table(st_ref,scripts,st_ref)\n\n"
      }
      mixin_tpl += "      end\n"

=begin
      # Sample RunScript
      unless script_array.empty?
        mixin_tpl += <<EOS
EOS
      end
=end
      # Exception Handle
      mixin_tpl += <<EOS

      # Every instance method included in the runner class that has
      # "exception_handle" in its name is called when an unhandled exception
      # is raised through a behavior (without a verification block). These
      # functions create a library of dynamic exception handling for common
      # scenarios. Exception_handle methods should return true if they have
      # handled the exception, or return false otherwise.
      def #{@@underscore_name}_exception_handle(e)
        if e.message =~ /INSERT YOUR ERROR HERE/
          puts "Got 'INSERT YOUR ERROR HERE'. Retrying..."
          sleep 30
          return true # Exception Handled
        else
          return false # Exception Not Handled
        end
      end
EOS

      # Black, White, Need lists
      MessageCheck::LISTS.each { |list|
        regex_ary = { MessageCheck::WHITELIST => ["harmless", "ignore"],
                      MessageCheck::BLACKLIST => ["exception", "error"],
                      MessageCheck::NEEDLIST => ["this should be here", "required line"] }
        mixin_tpl += <<EOS

      # Every instance method included in the runner class that has
      # "#{list}" in its name is called when the Class is instantiated.
      # These functions add entries to the #{list} for log auditing.
      # The function must return an array of length-3 arrays with the fields
      # as follows:
      #
      # [ "/path/to/log/file", "server_template_name_regex", "matching_regex" ]
      def #{@@underscore_name}_#{list}
        [
          #["/var/log/messages", "#{@@st_ary.first.nickname}", "#{regex_ary[list].first}"],
          #["/var/log/messages", "#{@@st_ary.last.nickname}", "#{regex_ary[list].last}"]
        ]
      end
EOS
      }

      mixin_tpl += <<EOS
    end
  end
end
EOS
      File.open(@@mixin_file, "w") { |f| f.write(mixin_tpl) }
    end

    def self.write_runner_file
      say("Creating runner file...")
      runner_tpl =<<EOS
module VirtualMonkey
  module Runner
    class #{@@camel_case_name}
      include VirtualMonkey::Mixin::DeploymentBase
      include VirtualMonkey::Mixin::#{@@camel_case_name}

      # Override any functions from mixins here
    end
  end
end
EOS
      File.open(@@runner_file, "w") { |f| f.write(runner_tpl) }
    end
  end
end
