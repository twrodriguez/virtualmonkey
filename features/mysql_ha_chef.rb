set :runner, VirtualMonkey::Runner::MysqlChefHA

# s_one - the first server that is used to create a DB from scratch in order to get a valid
# backup for additional testing.
# s_two - the first real master  created from do_restore_and_become_master using the from
# scracth backup
# s_three - the first slave restored from a newly launched state.
#

# Terminates servers if there are any running
hard_reset do
  stop_all
end

before do
   mysql_lookup_scripts
   set_variation_lineage
   set_variation_container
   setup_dns("virtualmonkey_awsdns_new") # dnsmadeeasy
   set_variation_dnschoice("text:Route53") # set variation choice
   launch_all
   wait_for_all("operational")
   disable_db_reconverge # it is important to disable this if we want to verify what backup we are restoring from
end

before "sequential_test", "verify_replication", "create_master_then_slave_from_slave_backup", "promote_slave_to_master", "promote_slave_with_dead_master", "secondary_backup_s3", "secondary_backup_cloudfiles", "reboot" do
   run_script("do_force_reset", s_one)
   run_script("do_force_reset", s_two)
   run_script("do_force_reset", s_three)

   run_script("setup_privileges_admin", s_one)

   # Need to setup a master from scratch to get the first backup for remaining tests
   #   tag/update dns for master
   #   create a block device
   #   add test tables into db
   #   write the backup
   run_script("do_tag_as_master", s_one)
   run_script("setup_block_device", s_one)
   create_monkey_table(s_one)
   #deletes backup, file, does backup, and waits for snapshot to complete
   do_backup(s_one)
   # Now we have a backup that can be used to restore master and slave
   # This server is not a real master.  To create a real master the
   # restore_and_become_master recipe needs to be run on a new instance
   # This one should be re-launched before additional tests are run on it
   #   transaction { s_one.relaunch }
   run_script("do_force_reset", s_one)
end

test "verify_replication" do
  verify_replication
end

test "create_master_then_slave_from_slave_backup" do
  create_master_then_slave_from_slave_backup
end


test "promote_slave_to_master" do
  promote_slave_to_master
end

test "promote_slave_with_dead_master" do
   promote_slave_with_dead_master
end

test "sequential_test"do
  sequential_test
end


#TODO checks for master vs slave backup setups
#  need to verify that the master servers backup cron job is using the master backup cron/minute/hour
#TODO enable and disable backups on both the master and slave servers -- this will be tested by hand -- inefficient by monkey


test "reboot" do
   #  reboot a slave, verify that it is operational, then add a table to master and verity replication
   #  reboot the master, verify opernational - " " ^
   # looks for a file that was written to the slave

   check_monitoring
   check_mysql_monitoring
   run_HA_reboot_operations
   check_monitoring
   check_mysql_monitoring

end

test "secondary_backup_s3" do
  test_secondary_backup_ha("S3")
end

test "secondary_backup_cloudfiles" do
  test_secondary_backup_ha("CloudFiles")
end

#after 'secondary_backup_s3', 'secondary_backup_cloudfiles', 'reboot' do
 # cleanup_volumes
#end

after do
@runner.release_dns
puts "after_do I actually work ****************$$$$$$$$$$$$$$$$$$$$$$$$$$$"
#  cleanup_volumes
#  cleanup_snapshots
end

