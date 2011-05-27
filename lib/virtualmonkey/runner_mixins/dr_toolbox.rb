module VirtualMonkey
  module DrToolbox

    # Stolen from ::EBS need to consolidate or dr_toolbox needs a terminate script to include ::EBS instead
    # take the lineage name, find all snapshots and sleep until none are in the pending state.
    def wait_for_snapshots
      timeout=1500
      step=10
      while timeout > 0
        puts "Checking for snapshot completed"
        snapshots = behavior(:find_snapshots)
        status = snapshots.map { |x| x.aws_status } 
        break unless status.include?("pending")
        sleep step
        timeout -= step
      end
      raise "FATAL: timed out waiting for all snapshots in lineage #{@lineage} to complete" if timeout == 0
    end

    # Find all snapshots associated with this deployment's lineage
    def find_snapshots
      unless @lineage
        s = @servers.first
        kind_params = s.transform_parameters(s.parameters)
        @lineage = kind_params['DB_LINEAGE_NAME'].gsub(/text:/, "")
      end
      snapshots = Ec2EbsSnapshot.find_by_cloud_id(@servers.first.cloud_id).select { |n| n.nickname =~ /#{@lineage}.*$/ }
    end

    def set_variation_lineage
      @lineage = "testlineage#{resource_id(@deployment)}"
      obj_behavior(@deployment, :set_input, "block_device/lineage", "text:#{@lineage}")
    end

    def set_variation_container
      @container = "testlineage#{resource_id(@deployment)}"
      obj_behavior(@deployment, :set_input, "block_device/storage_container", "text:#{@container}")
    end

    # Pick a storage_type depending on what cloud we're on.
    def set_variation_storage_type
      cid = VirtualMonkey::Toolbox::determine_cloud_id(s_one)
      if cid == 232
        @storage_type = "ros"
      else
        pick = rand(100000) % 2
        if pick == 1
          @storage_type = "ros"
        else
          @storage_type = "volume"
        end
      end
      puts "STORAGE_TYPE: #{@storage_type}"
 
      obj_behavior(@deployment, :set_input, "block_device/storage_type", "text:#{@storage_type}")
    end

    def test_s3
    #  behavior(:run_script, "do_force_reset", s_one)
    #  sleep 10
    #  behavior(:run_script, "setup_lvm_device_ec2_ephemeral", s_one)
      probe(s_one, "touch /mnt/storage/monkey_was_here")
      sleep 10
      behavior(:run_script, "do_backup_s3", s_one)
      sleep 10
      behavior(:run_script, "do_force_reset", s_one)
      sleep 10
      behavior(:run_script, "do_restore_s3", s_one)
      probe(s_one, "ls /mnt/storage") do |result, status|
        raise "FATAL: no files found in the backup" if result == nil || result.empty?
        true
      end
    end

    def test_ebs
      # EBS is already setup, to save time we'll skip the force_reset
      #behavior(:run_script, "do_force_reset", s_one)
      #sleep 10
      #behavior(:run_script, "setup_lvm_device_ebs", s_one)
      probe(s_one, "touch /mnt/storage/monkey_was_here")
      sleep 10
      behavior(:run_script, "do_backup_ebs", s_one)
      wait_for_snapshots
      behavior(:run_script, "do_force_reset", s_one)
# need to wait here for the volume status to settle (detaching)
      sleep 200
      behavior(:run_script, "do_restore_ebs", s_one)
      probe(s_one, "ls /mnt/storage") do |result, status|
        raise "FATAL: no files found in the backup" if result == nil || result.empty?
        true
      end
    end

    def test_cloud_files
    #  behavior(:run_script, "do_force_reset", s_one)
    #  sleep 10
    #  behavior(:run_script, "setup_lvm_device_rackspace", s_one)
      probe(s_one, "touch /mnt/storage/monkey_was_here")
      sleep 10
      behavior(:run_script, "do_backup_cloud_files", s_one)
      sleep 10
      behavior(:run_script, "do_force_reset", s_one)
      sleep 10
      behavior(:run_script, "do_restore_cloud_files", s_one)
      probe(s_one, "ls /mnt/storage") do |result, status|
        raise "FATAL: no files found in the backup" if result == nil || result.empty?
        true
      end
    end

    # pick the right set of tests depending on what cloud we're on
    def test_multicloud
      cid = VirtualMonkey::Toolbox::determine_cloud_id(s_one)
      if cid == 232
        test_cloud_files
      else
        if @storage_type == "ros"
          test_s3
        elsif @storage_type == "volume"
          test_ebs
        end
      end
    end
   
  end
end

