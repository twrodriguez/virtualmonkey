set :runner, VirtualMonkey::Runner::SimpleWindowsAD

before do
  @runner.stop_all


  @runner.launch_all


  @runner.wait_for_all("operational")
end

test "default" do

  @runner.check_monitoring



  @runner.run_script_on_all("AD monkey test")
  @runner.run_script_on_all("AD change Administrator password")  
  @runner.run_script_on_all("SYS Install AD Backup Policy")
  @runner.run_script_on_all("SYS Install AD Backup Policy CHECK")
  @runner.run_script_on_all("AD create a new user")
  @runner.run_script_on_all("AD create a new user CHECK")
  @runner.run_script_on_all("AD create a new group")  
  @runner.run_script_on_all("AD create a new group CHECK")
  @runner.run_script_on_all("AD bulk add user")
  @runner.run_script_on_all("AD bulk add user CHECK")
  @runner.run_script_on_all("AD install ADFS")
  @runner.run_script_on_all("AD install ADFS CHECK")
  @runner.run_script_on_all("SYS change to safe boot mode")
  @runner.run_script_on_all("AD create a backup")
  
  # After booting in DRSM mode rightlink service does not work
  #@runner.run_script_on_all("SYS change to safe boot mode CHECK")
  #@runner.run_script_on_all("SYS change to normal boot mode")
  #@runner.run_script_on_all("SYS change to normal boot mode CHECK")
  
end
