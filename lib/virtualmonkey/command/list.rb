module VirtualMonkey
  module Command
    # bin/monkey list -x
    add_command("list", [:prefix, :verbose, :yes, :config_file]) do
      load_config_file
      VirtualMonkey::Manager::DeploymentSet.list(@@options[:prefix], @@options[:verbose])
    end
  end
end
