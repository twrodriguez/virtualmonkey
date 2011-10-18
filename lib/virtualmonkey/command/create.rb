module VirtualMonkey
  module Command
    # monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    add_command("create", [:config_file, :clouds, :only, :no_spot, :one_deploy, :prefix, :yes, :verbose,
                           :use_mci, :revisions, :force, :overwrite]) do
      raise "--config_file is required" unless @@options[:config_file]
      load_config_file
      @@dm = DeploymentMonk.new(@@options[:prefix],
                                @@options[:server_template_ids],
                                [],
                                @@options[:allow_meta_monkey],
                                @@options[:one_deploy])
      if @@dm.deployments.size < 1
        create_logic
      elsif @@options[:overwrite]
        if @@options[:force]
          begin
            destroy_all_logic
          rescue Exception => e
            warn "WARNING: got \"#{e.message}\", forcing destruction of deployments."
            @@do_these.each { |deploy|
              deploy.servers_no_reload.each { |s| s.stop if s.state =~ /operational|booting/ }
              deploy.destroy
            }
            SharedDns.release_all_unused_domains
          end
        else
          destroy_all_logic
        end
        go(@@last_command_line)
      else
        warn "Existing deployments matching --prefix #{@@options[:prefix]} found. Skipping deployment creation."
      end
    end
  end
end
