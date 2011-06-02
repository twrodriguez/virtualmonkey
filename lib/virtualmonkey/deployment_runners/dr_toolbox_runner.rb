module VirtualMonkey
  class DrToolboxRunner
    include VirtualMonkey::DeploymentBase
    include VirtualMonkey::DrToolbox
    include VirtualMonkey::Chef
# once dr toolbox gets a terminate script, we can use the mixin for ebs..
#    include VirtualMonkey::EBS
    def lookup_scripts
      scripts = [
                 [ 'setup_block_device', 'block_device::setup_block_device' ],
                 [ 'do_backup', 'block_device::do_backup' ],
                 [ 'do_backup_s3', 'block_device::do_backup_s3' ],
                 [ 'do_backup_ebs', 'block_device::do_backup_ebs' ],
                 [ 'do_backup_cloud_files', 'block_device::do_backup_cloud_files' ],
                 [ 'do_restore_s3', 'block_device::do_restore_s3' ],
                 [ 'do_restore', 'block_device::do_restore' ],
                 [ 'do_restore_ebs', 'block_device::do_restore_ebs' ],
                 [ 'do_restore_cloud_files', 'block_device::do_restore_cloud_files' ],
                 [ 'do_restore_cloud_files', 'block_device::do_restore_cloud_files' ],
                 [ 'do_force_reset', 'block_device::do_force_reset' ]
                 ]
       st = ServerTemplate.find(resource_id(s_one.server_template_href))
      load_script_table(st,scripts)
    end

  end
end
