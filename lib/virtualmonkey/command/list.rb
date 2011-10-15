module VirtualMonkey
  module Command
    # bin/monkey list -x
    add_command("list", [:prefix, :verbose, :yes]) do
      DeploymentMonk.list(@@options[:prefix], @@options[:verbose])
    end
  end
end
