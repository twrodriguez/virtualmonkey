module VirtualMonkey
  module Command
    # monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    add_command("create", [:config_file, :clouds, :only, :no_spot, :one_deploy, :prefix, :yes, :verbose,
                           :use_mci, :revisions, :force, :overwrite]) do
      raise "--config_file is required" unless @@options[:config_file]

      create_command_ary = VirtualMonkey::Command::reconstruct_command_line(:Array)

      load_config_file
      @@dm = VirtualMonkey::Manager::DeploymentSet.new(@@options)
      if @@options[:overwrite] && @dm.deployments.size > 0
        if @@options[:force]
          begin
            destroy_all_logic
          rescue Interrupt
            raise
          rescue Exception => e
            warn "WARNING: got \"#{e.message}\", forcing destruction of deployments."
            @@do_these.each { |deploy|
              deploy.servers_no_reload.each { |s| s.stop if s.state =~ /operational|booting/ }
              deploy.destroy
            }
          end
        else
          destroy_all_logic
        end
        # Store for later
        create_command_string = @@last_command_line

        reset
        go(*create_command_ary)

        # Restore last_command_line
        @@last_command_line = create_command_string
      elsif @@dm.deployments.size < 1 || @@options[:force]
        create_logic
      else
        warn "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end
    end
  end
end
