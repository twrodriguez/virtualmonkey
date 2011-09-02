set :runner, VirtualMonkey::Runner::SimpleWindowsSQL

hard_reset do
  @runner.stop_all
end

before do
  @runner.set_test_lineage
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "backup_restore" do
  @runner.run_script_on_all("sql_db_check")
  @runner.run_script_on_all("EBS Backup data and log volumes")
  @runner.run_script_on_all("DB SQLS DISABLE SERVER - snapshot, detach and delete volumes")

  @runner.relaunch_all

  @runner.run_script_on_all("EBS Restore data and log volumes")
  @runner.run_script_on_all("sql_db_check")
  @runner.run_script_on_all("DB SQLS Rename instance")
  @runner.run_script_on_all("new_name_check")
end

test "check_monitoring" do
  @runner.check_monitoring
end

before "backup_restore", "extra_tests" do
  @runner.run_script_on_all("EBS Create data and log volumes")
end

test "extra_tests" do
  @runner.run_script_on_all("DB SQLS Configure tempdb")
  @runner.run_script_on_all("tempdb_check")
  @runner.run_script_on_all("DB SQLS create user")
  @runner.run_script_on_all("newuser_check")
  @runner.run_script_on_all("load_db")
  @runner.run_script_on_all("log_repair_before")
  @runner.run_script_on_all("DB SQLS Repair log files")
  @runner.run_script_on_all("log_repair_after")
end

after do
  @runner.cleanup_volumes
  @runner.cleanup_snapshots
end
