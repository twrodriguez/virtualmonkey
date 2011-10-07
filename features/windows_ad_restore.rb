set :runner, VirtualMonkey::Runner::SimpleWindowsAD

before do
  @runner.stop_all


  @runner.launch_all


  @runner.wait_for_all("operational",72000)
end

test "default" do

  @runner.check_monitoring

  @runner.run_script_on_all("SYS change to safe boot mode")
  @runner.run_script_on_all("AD Restore from backup",300*60)
  @runner.run_script_on_all("AD Rebuild domain shares")
  @runner.run_script_on_all("AD monkey test",30*60)
  @runner.run_script_on_all("AD Change Administrator password")  
  @runner.run_script_on_all("SYS Install AD backup policy")
  @runner.run_script_on_all("SYS Install AD Backup Policy CHECK")
  @runner.run_script_on_all("AD Create a new user")
  @runner.run_script_on_all("AD create a new user CHECK")
  @runner.run_script_on_all("AD Create a new group")
  @runner.run_script_on_all("AD create a new group CHECK")
  @runner.run_script_on_all("AD Bulk create new user",120*60)
  @runner.run_script_on_all("AD bulk add user CHECK")
  @runner.run_script_on_all("AD Install ADFS",4800*60)
  @runner.run_script_on_all("AD install ADFS CHECK")
  # After booting in DSRM mode rightlink service does not work
  #@runner.run_script_on_all("SYS change to safe boot mode CHECK")
  #@runner.run_script_on_all("SYS Change to normal boot mode")
  #@runner.run_script_on_all("SYS change to normal boot mode CHECK")
  
end
