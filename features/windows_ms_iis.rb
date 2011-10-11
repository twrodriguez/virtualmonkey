set :runner, VirtualMonkey::Runner::SimpleWindowsIIS

hard_reset do
  @runner.stop_all
end

before do
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.check_monitoring
  @runner.run_script_on_all("IIS Monkey tests")
  @runner.run_script_on_all("IIS Download application code")
  @runner.run_script_on_all("IIS Add connection string")
  @runner.run_script_on_all("IIS Switch default website")
  @runner.run_script_on_all("IIS Restart application")
  @runner.run_script_on_all("IIS Restart web server")
  @runner.run_script_on_all("IIS Restart web server check")
  @runner.run_script_on_all("AWS Register with ELB")
  @runner.run_script_on_all("AWS Deregister from ELB")
  @runner.run_script_on_all("SYS Install Web Deploy 2.0")
  @runner.run_script_on_all("SYS Install Web Deploy 2.0 check")
  @runner.run_script_on_all("SYS Install ASP.NET MVC 3")
  @runner.run_script_on_all("SYS Install ASP.NET MVC 3 check")
  @runner.run_script_on_all("SYS Install .NET Framework 4")
  @runner.run_script_on_all("SYS Install .NET Framework 4 check")
  @runner.run_script_on_all("IIS web server check")
end

before "no_volumes" do
  @runner.set_no_volumes
end

test "no_volumes" do
  @runner.check_monitoring
  @runner.run_script_on_all("IIS Monkey tests")
  @runner.run_script_on_all("IIS Download application code")
  @runner.run_script_on_all("IIS Add connection string")
  @runner.run_script_on_all("IIS Switch default website")
  @runner.run_script_on_all("IIS Restart application")
  @runner.run_script_on_all("IIS Restart web server")
  @runner.run_script_on_all("IIS Restart web server check")
  @runner.run_script_on_all("IIS web server check")
end





