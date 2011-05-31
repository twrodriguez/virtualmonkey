module VirtualMonkey
  class DrToolboxRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::DrToolbox
# once dr toolbox gets a terminate script, we can use the mixin for ebs..
#    include VirtualMonkey::EBS
    def lookup_scripts
      scripts = [
                 [ 'setup_lvm_device_ec2_ephemeral', 'block_device::setup_lvm_device_ec2_ephemeral' ],
                 [ 'setup_lvm_device_ebs', 'block_device::setup_lvm_device_ebs' ],
                 [ 'setup_lvm_device_rackspace', 'block_device::setup_lvm_device_rackspace' ],
                 [ 'do_backup_s3', 'block_device::do_backup_s3' ],
                 [ 'do_backup_ebs', 'block_device::do_backup_ebs' ],
                 [ 'do_backup_cloud_files', 'block_device::do_backup_cloud_files' ],
                 [ 'do_restore_s3', 'block_device::do_restore_s3' ],
                 [ 'do_restore_ebs', 'block_device::do_restore_ebs' ],
                 [ 'do_restore_cloud_files', 'block_device::do_restore_cloud_files' ],
                 [ 'do_restore_cloud_files', 'block_device::do_restore_cloud_files' ],
                 [ 'do_force_reset', 'block_device::do_force_reset' ],
                 ]
       st = ServerTemplate.find(resource_id(s_one.server_template_href))
      load_script_table(st,scripts)
    end

  end
end
