module VirtualMonkey
  module Runner
    class MonkeyDiagnostic
      extend VirtualMonkey::RunnerCore::CommandHooks
      include VirtualMonkey::RunnerCore::DeploymentBase
      include VirtualMonkey::Mixin::MonkeyDiagnostic

      description "Tests the $0 aspects of the VirtualMonkey ServerTemplate and codebase"

      def initialize(*args)
        raise "FATAL: #{self.class} must be run in the cloud" unless VirtualMonkey::my_api_self
        super(*args)
        @my_inputs = {}
        @cloud = VirtualMonkey::my_api_self.cloud_id
        @commands = VirtualMonkey::Command::AvailableCommands.keys.map_to_h { |cmd| [] }
        populate_commands
        load_inputs
      end

      def monkey_diagnostic_lookup_scripts
        scripts = [
                   ['generate cloud data', 'RB virtualmonkey generate cloud test data'],
                   ['destroy cloud data', 'RB virtualmonkey destroy cloud test data']
                  ]
        st = ServerTemplate.find(resource_id(VirtualMonkey::my_api_self.server_template_href).to_i)
        load_script_table(st,scripts)
      end

      def populate_commands
        # Basic (Free) Commands
        @commands[:help] = @commands.keys.map { |cmd| cmd.to_s } - ["help"]
        @commands[:api_check] += ["-a 0.1", "-a 1.0", "-a 1.5"]
        @commands[:version] << ""
        @commands[:config] = VirtualMonkey::Command::ConfigOptions.keys - ["edit", "set", "unset", "get"] #TODO

        # Commands that need Scenarios
        @commands.delete :populate_all_cloud_vars
        @commands.delete :populate_datacenters
        @commands.delete :populate_security_groups
        @commands.delete :generate_ssh_keys
        @commands.delete :destroy_ssh_keys

        @commands.delete :import_deployment #TODO need a way to test without interactivity
        @commands.delete :new_config #TODO need a way to test without interactivity
        @commands.delete :new_runner #TODO need a way to test without interactivity

        @commands.delete :create
        @commands.delete :list
        @commands.delete :run
        @commands.delete :clone
        @commands.delete :update_inputs
        @commands.delete :destroy
        @commands.delete :troop

        # $$$ Commands
        #@commands[:create] << "-x #{@prefix} -f #{troop_file} -i #{@cloud}"
        #@commands[:run] << "-x #{@prefix} -f #{troop_file} -i #{@cloud} -y"
        #@commands[:clone]
        #@commands[:update_inputs]
        #@commands[:destroy] << "-x #{@prefix} -f #{troop_file} -i #{@cloud} -y"
        #@commands[:troop] << "-x #{@prefix} -f #{troop_file} -i #{@cloud}"
      end

      def pull_branch
        if @options[:runner_options]["branch"]
          @root_dir = File.join("", "tmp", "virtualmonkey")
          repo_url = @my_inputs["VIRTUAL_MONKEY_REPO_URL"].split(/ -b /).first
          FileUtils.mkdir_p(File.join(@root_dir, ".."))
          `cd #{File.join(@root_dir, "..")}; git clone #{repo_url} -b #{branch}`

          # Test Syntax and Dependencies
          result = `cd #{@root_dir}; bin/monkey help; echo $?`.chomp
          result =~ /([0-9]+)$/
          exit_status = $1.to_i
          if exit_status != 0
            result =~ /(.*)[0-9]+$/
            raise "FATAL: Branch '#{branch}' failed syntax and dependency check:\n#{$1}"
          end
        else
          @root_dir = VirtualMonkey::ROOTDIR
        end
      end

      def cleanup_branch
        FileUtils.rm_rf(@root_dir) if @options[:runner_options]["branch"] and File.directory?(@root_dir)
      end

      def run_self_diagnostic
        @commands.keys.each { |cmd|
          @commands[cmd].each { |opts|
            if @root_dir == VirtualMonkey::ROOTDIR
              puts "Running bin/monkey #{cmd} #{opts}"
              begin
                VirtualMonkey::Command.__send__(cmd, opts)
              rescue SystemExit => e
              end
            else
              result = `cd #{@root_dir}; bin/monkey #{cmd} #{opts}; echo $?`.chomp
              result =~ /([0-9]+)$/
              exit_status = $1.to_i
              if exit_status != 0
                result =~ /(.*)[0-9]+$/
                raise "FATAL: Command 'bin/monkey #{cmd} #{opts}' failed:\n#{$1}"
              end
            end
          }
        }
        # TODO generate/destroy cloud_variables
      end
    end
  end
end
