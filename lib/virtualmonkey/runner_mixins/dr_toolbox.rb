module VirtualMonkey
  module Mixin
    module DrToolbox

      # Stolen from ::EBS need to consolidate or dr_toolbox needs a terminate script to include ::EBS instead
      # take the lineage name, find all snapshots and sleep until none are in the pending state.
      def wait_for_snapshots
        timeout=1500
        step=10
        while timeout > 0
          puts "Checking for snapshot completed"
          snapshots =find_snapshots
          status = snapshots.map { |x| x.aws_status }
          break unless status.include?("pending")
          sleep step
          timeout -= step
        end
        raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout == 0
      end

      # Find all snapshots associated with this deployment's lineage
      def find_snapshots
        s = @servers.first
        unless @lineage
          kind_params = s.parameters
          @lineage = kind_params['db/backup/lineage'].gsub(/text:/, "")
        end
        if s.cloud_id.to_i < 10
          snapshots = Ec2EbsSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}")
        elsif s.cloud_id.to_i == 232
          snapshots = [] # Ignore Rackspace, there are no snapshots
        else
          snapshots = McVolumeSnapshot.find_by_tags("rs_backup:lineage=#{@lineage}").select { |vs| vs.cloud.split(/\//).last.to_i == s.cloud_id.to_i }
        end
        snapshots
      end

      def find_snapshot_timestamp(server, provider = :volume)
        case provider
        when :volume
          if server.cloud_id.to_i != 232
            last_snap = find_snapshots.last
            last_snap.tags(true).detect { |t| t =~ /timestamp=(\d+)$/ }
            timestamp = $1
          else #Rackspace uses cloudfiles object store
            cloud_files = Fog::Storage.new(:provider => 'Rackspace')
            if dir = cloud_files.directories.detect { |d| d.key == @container }
              dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
              timestamp = $1
            end
          end
        when "S3"
          s3 = Fog::Storage.new(:provider => 'AWS')
          if dir = s3.directories.detect { |d| d.key == @container }
            dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
            timestamp = $1
          end
        when "CloudFiles"
          cloud_files = Fog::Storage.new(:provider => 'Rackspace')
          if dir = cloud_files.directories.detect { |d| d.key == @container }
            dir.files.first.key =~ /-([0-9]+\/[0-9]+)/
            timestamp = $1
          end
        else
          raise "FATAL: Provider #{provider.to_s} not supported."
        end
        return timestamp
      end

      def set_variation_lineage
        @lineage = "testlineage#{resource_id(@deployment)}"
        @deployment.set_input("block_device/lineage", "text:#{@lineage}")
        @servers.each do |server|
          server.set_inputs({"block_device/lineage" => "text:#{@lineage}"})
        end
      end

      def set_variation_container
        @container = "testlineage#{resource_id(@deployment)}"
        @deployment.set_input("block_device/storage_container", "text:#{@container}")
        @servers.each do |server|
          server.set_inputs({"block_device/storage_container" => "text:#{@container}"})
        end
      end

      # Pick a storage_type depending on what cloud we're on.
      def set_variation_storage_type(storage = :volume)
        if s_one.cloud_id.to_i == 232 # Rackspace
          @storage_type = "ros"
        elsif s_one.cloud_id.to_i < 10
          @storage_type = storage
        else
          @storage_type = :volume
        end
        puts "STORAGE_TYPE: #{@storage_type}"
        @storage_type = ENV['STORAGE_TYPE'] if ENV['STORAGE_TYPE']

        @deployment.set_input("block_device/storage_type", "text:#{@storage_type}")
        @servers.each do |server|
          server.set_inputs({"block_device/storage_type" => "text:#{@storage_type}"})
        end
      end

      def set_variation_mount_point(mount_point = '/mnt/storage')
        @mount_point = mount_point

        @deployment.set_input('block_device/mount_dir', "text:#{@mount_point}")
        @servers.each do |server|
          server.set_inputs({'block_device/mount_dir' => "text:#{@mount_point}"})
        end
      end

      def test_backup(type = :volume)
        if s_one.cloud_id.to_i == 232 and type == "CloudFiles"
          puts "Skipping Rackspace Object Backup since Volume uses CloudFiles"
        else
          @backup_methods_tested ||= {}
          return true if @backup_methods_tested[type]
          type = "CloudFiles" if s_one.cloud_id.to_i == 232 and type == :volume
          set_variation_storage_type((type == :volume ? type : "ros"))
          provider = type.to_s.underscore
          run_script("setup_block_device", s_one)
          probe(s_one, "dd if=/dev/urandom of=#{@mount_point}/monkey_was_here bs=4M count=100")
          run_script("do_backup_#{provider}", s_one)
          sleep 15
          wait_for_snapshots if provider == "volume"
          sleep 15
          run_script("do_force_reset", s_one)
          sleep 15
          run_script("do_restore_#{provider}", s_one)
          sleep 15
          probe(s_one, "ls #{@mount_point}") do |result, status|
            raise "FATAL: no files found in the backup" if result == nil || result.empty?
            true
          end
          run_script("do_force_reset", s_one)
          sleep 15
          run_script("do_restore_#{provider}", s_one, { "block_device/timestamp_override" =>
                                                        "text:#{find_snapshot_timestamp(s_one, type)}" })
          sleep 15
          probe(s_one, "ls #{@mount_point}") do |result, status|
            raise "FATAL: no files found in the backup" if result == nil || result.empty?
            true
          end
          @backup_methods_tested[type] = true
        end
      end

      def cleanup_snapshots
        find_snapshots.each do |snap|
          snap.destroy
        end
        # TODO cleanup buckets
      end

      def cleanup_volumes
        @servers.each do |server|
          unless ["stopped", "pending", "inactive", "decommissioning", "terminating"].include?(server.state)
            run_script("do_force_reset", server)
          end
        end
      end

      def test_continuous_backups(type = :volume)
        @passed_continuous_backups ||= false
        if @passed_continuous_backups
          # Skip continuous part if we've already tested continuous backups
          test_backup(type)
          return true
        end
        return true if s_one.cloud_id.to_i == 232 and type == :volume # Rackspace can't do volumes
        if type == :volume
          set_variation_storage_type(:volume)
        else
          set_variation_storage_type("ros")
          if type == "S3"
            fog_store = Fog::Storage.new(:provider => 'AWS')
          elsif type == "CloudFiles"
            fog_store = Fog::Storage.new(:provider => 'Rackspace')
          else
            raise "FATAL: Bad ObjectStore value!"
          end
        end
        provider = type.to_s.underscore
        run_script("setup_block_device", s_one)

        # Setup Backups for every 3 minutes
        total_sleep_time = 0
        every_n_minutes = 3
        tick = every_n_minutes * 60 # Number of seconds between cron jobs
        opts = {"block_device/cron_backup_hour" => "text:*",
                "block_device/cron_backup_minute" => "text:*/#{every_n_minutes}"}
        run_script("setup_continuous_backups_#{provider}", s_one, opts)

        # Wait for snapshots to be created
        retries = 0
        if type == :volume
          snapshots = find_snapshots
          until snapshots.length > 0
            retries += 1
            raise "FATAL: Retry count exceeded 10; Failed Continuous Backup Enable Test" unless retries < 10
            sleep(tick / 3)
            total_sleep_time += (tick / 3)
            snapshots = find_snapshots
          end
        else
          until dir = fog_store.directories.detect { |d| d.key == @container }
            retries += 1
            raise "FATAL: Retry count exceeded 10; Failed Continuous Backup Enable Test" unless retries < 10
            sleep(tick / 3)
            total_sleep_time += (tick / 3)
          end
        end

        # get file count
        if type == :volume
          count = snapshots.length
          sleep(tick)
          total_sleep_time += tick
          raise "FATAL: Failed Continuous Backup Enable Test" unless find_snapshots.length > count
        else
          count = dir.files.length
          sleep(tick)
          total_sleep_time += tick
          dir.files.reload
          raise "FATAL: Failed Continuous Backup Enable Test" unless dir.files.length > count
        end

        # Disable cron job
        run_script("do_disable_continuous_backups_#{provider}", s_one)
        time_to_sleep = (((total_sleep_time - tick)**2)/60)
        while time_to_sleep > 0
          sleep(tick)
          time_to_sleep -= tick
          # rest_connection keep alive calls:
          # - API 0.1 Class connection
          # - API 1.0 Class connection
          # - API 1.5 Class connection
          # - API 0.1 Instance connection
          # - API 1.0 Instance connection
          # - API 1.5 Instance connection
          ServerTemplate.find(@server_templates.first.reload['href']).multi_cloud_images.each { |mci_i| mci_i.reload }
        end
        if type == :volume
          count = find_snapshots.length
          sleep(total_sleep_time - tick)
          raise "FATAL: Failed Continuous Backup Disable Test" unless find_snapshots.length == count
        else
          count = dir.files.length
          sleep(total_sleep_time - tick)
          dir.files.reload
          raise "FATAL: Failed Continuous Backup Disable Test" unless dir.files.length == count
        end
        @passed_continuous_backups = true
      end

      def release_container
        set_variation_container
        ary = []
        raise "FATAL: could not cleanup because @container was '#{@container}'" unless @container
        s3 = Fog::Storage.new(:provider => 'AWS')
        ary << s3.directories.all.select {|d| d.key =~ /^#{@container}/}
        if Fog.credentials[:rackspace_username] and Fog.credentials[:rackspace_api_key]
          rax = Fog::Storage.new(:provider => 'Rackspace')
          ary << rax.directories.all.select {|d| d.key =~ /^#{@container}/}
        else
          puts "No Rackspace Credentials!"
        end
        ary.each do |con|
          con.each do |dir|
            dir.files.each do |file|
              file.destroy
            end
            dir.destroy
          end
        end
      end

    end
  end
end
