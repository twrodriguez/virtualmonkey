module VirtualMonkey
  module Command
    # This command does all the steps create/run/conditionaly destroy
    add_command("troop", [:config_file, :no_spot, :prefix, :use_mci, :verbose, :yes, :one_deploy, :keep,
                          :clouds, :only, :tests, :no_resume, :revisions, :report_tags, :report_metadata]) do
      # Execute Main
      load_config_file

      # CREATE PHASE
      @@dm = DeploymentMonk.new(@@options[:prefix],
                                @@options[:server_template_ids],
                                [],
                                @@options[:allow_meta_monkey],
                                @@options[:single_deployment])
      unless @@dm.deployments.size > 0
        create_logic
      else
        warn "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end

      run_logic
    end
  end
end
