module VirtualMonkey
  module Command
    # monkey destroy --tag unique_tag
    add_command("destroy", [:config_file, :only, :keep, :prefix, :yes, :clouds, :verbose, :force]) do
      load_config_file
      @@dm = DeploymentMonk.new(@@options[:prefix], [], [], @@options[:allow_meta_monkey])
      select_only_logic("Really destroy")
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
    end
  end
end
