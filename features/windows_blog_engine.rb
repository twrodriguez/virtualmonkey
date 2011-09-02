set :runner, VirtualMonkey::Runner::SimpleWindowsBlog

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
#  @runner.check_monitoring
  @runner.run_script_on_all("backup_database")
  @runner.run_script_on_all("backup_database_check")
  @runner.run_script_on_all("drop_database")
  @runner.run_script_on_all("restore_database")
end
