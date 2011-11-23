module VirtualMonkey
  module Command
    # bin/monkey list -x
    add_command("list", [:prefix, :verbose, :yes, :config_file], [], :flagless) do
      load_config_file if @@options[:config_file]
      @@options[:prefix] ||= "*"
      VirtualMonkey::Manager::DeploymentSet.list(@@options[:prefix], @@options[:verbose])
    end
  end
end
