module VirtualMonkey
  module Runner
    class MonkeyMetaTroop
      extend VirtualMonkey::RunnerCore::CommandHooks
      include VirtualMonkey::RunnerCore::DeploymentBase

      description <<EOS
Tests the VirtualMonkey ServerTemplate in full permutation and verifies that it can run in multiple
cloud environments and OSes
EOS

      def initialize(*args)
        raise "FATAL: #{self.class} must be run in the cloud" unless ::VirtualMonkey::my_api_self
        super(*args)
        @prefix = "#{prefix}_MONKEY_META_TROOP"
        @troop_log = "/tmp/troop.log"
        @exit_log = "/tmp/troop_exit_st.log"
        @free_commands = {}
        @my_inputs = {}
        @cloud = @servers.first.cloud_id
        ::VirtualMonkey::my_api_self
        @commands = ::VirtualMonkey::Command::AvailableCommands.keys.map { |cmd| [cmd.to_s, []] }.to_h
        populate_commands
        load_inputs
      end

      def monkey_meta_troop_lookup_scripts
        scripts = [
                   ['generate cloud data', 'RB virtualmonkey generate cloud test data'],
                   ['destroy cloud data', 'RB virtualmonkey destroy cloud test data']
                  ]
        st = @server_templates.first
        load_script_table(st,scripts)
      end

      def populate_commands
        troop_file = File.join(::VirtualMonkey::ROOTDIR, "config", "troop", troop)
        # Basic (Free) Commands
        @free_commands["help"] = @commands.keys.dup - ["help"]
        @free_commands["api_check"] += ["-a 0.1", "-a 1.0", "-a 1.5"]
        @free_commands["version"] << ""

        # Non-testing commands
        @commands.delete "help"
        @commands.delete "api_check"
        @commands.delete "version"
        @commands.delete "import_deployment"
        @commands.delete "new_troop_config"
        @commands.delete "new_runner"
        @commands.delete "populate_all_cloud_vars"
        @commands.delete "populate_datacenters"
        @commands.delete "populate_security_groups"

        # $$$ Commands
        @commands["create"] << "-x #{@prefix} -f #{troop_file} -i #{@cloud}"
        @commands["run"] << "-x #{@prefix} -f #{troop_file} -i #{@cloud} -y"
        @commands["clone"]
        @commands["update_inputs"]
        @commands["destroy"] << "-x #{@prefix} -f #{troop_file} -i #{@cloud} -y"
        @commands["troop"] << "-x #{@prefix} -f #{troop_file} -i #{@cloud}"
      end

      def set_inputs
        @servers.each { |server| server.set_inputs(@my_inputs) }
      end

      def pull_branch
        if @options[:runner_options]["branch"]
          probe(@servers.first, "cd /root/virtualmonkey; git pull origin #{branch}") { |result,status|
            raise result if result =~ /(aborting)|(error)|(fatal)|(failed)/i
            true
          }
        end
      end

      def test_free_commands
        @free_commands.keys.each { |cmd|
          @free_commands[cmd].each { |opts|
            cmd_str = "cd /root/virtualmonkey; bin/monkey #{cmd} #{opts}"
            probe(@servers.first, cmd_str) { |result, status|
              raise result if status != 0
              true
            }
          }
        }
      end

      def run_troop
        ["create", "run", "destroy"].each { |cmd|
          transaction {
            # Start Monkey Command in the background
            troop_cmd = "$(bin/monkey #{cmd} -x #{@prefix} -f config/troop/#{troop}; echo $? > #{@exit_log})"
            job_id = nil
            probe(@servers.first, "cd /root/virtualmonkey; #{troop_cmd} &>> #{@troop_log} &") { |result, status|
              job_id = result.split(/ |\n/).last.to_i
              true
            }
            # Wait for command to complete
            job_running = true
            while job_running
              sleep 30
              probe(@servers.first, "ps #{job_id}") { |result, status| job_running = (status == 0); true }
            end
            # Get console output
            probe(@servers.first, "cat #{@troop_log}") { |result, status|
              File.open(@log_map["console_output.log"], "w") { |f| f.write(result) }
              true
            }
            # Parse logs
            probe(@servers.first, "cat #{@exit_log}") { |result, status|
              if result.to_i != 0
                File.open(@log_map["console_output.log"], "w") { |f| f.write(result) }
                raise "FATAL: #{cmd} failed. See console_output.log for a detailed view."
              else
                if IO.read(@log_map["console_output.log"]) =~ /(http:\/\/s3.amazonaws.com\/[^\n]*\/index.html)/
                  index_html = `curl -s #{$1}`
                  File.open(@log_map["index.html"], "w") { |f| f.write(index_html) }
                end
              end
              true
            }
          }
        }
      end
    end
  end
end
