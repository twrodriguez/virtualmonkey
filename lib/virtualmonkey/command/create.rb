module VirtualMonkey
  module Command
    # monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    add_command("create", [:config_file, :clouds, :only, :no_spot, :one_deploy, :prefix, :yes, :verbose,
                           :use_mci, :revisions]) do
      raise "--config_file is required" unless @@options[:config_file]
      load_config_file
      @@dm = DeploymentMonk.new(@@options[:prefix],
                                @@options[:server_template_ids],
                                [],
                                @@options[:allow_meta_monkey],
                                @@options[:one_deploy])
      unless @@dm.deployments.size > 0
        create_logic
      else
        warn "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end
    end
  end
end
