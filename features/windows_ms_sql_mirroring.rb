set :runner, VirtualMonkey::Runner::SimpleWindowsSqlsMirroring

before do
  @runner.stop_all
  @runner.set_mirroring_inputs
  @runner.launch_set(:toolbox_server)
  @runner.wait_for_set(:toolbox_server, "operational")
end

test "default" do

  @runner.run_script_on_set("EBS Create data and log volumes v1", :toolbox_server)
  @runner.run_script_on_set("SQLS CHECK volumes created", :toolbox_server)
  @runner.run_script_on_set("EBS Create backup volume", :toolbox_server)
  @runner.run_script_on_set("SQLS CHECK backup volume created", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Configure tempdb", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK tempdb configured", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Restore from disk/S3 v1", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK restore from disk/S3 ok", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Set Full Recovery Model", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK full recovery model set", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Set default backup compression", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK backup compression set", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Create login v1", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK login created", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Switch mirroring off", :toolbox_server)
  @runner.run_script_on_set("SQLS CHECK mirroring switched off", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Backup to disk/S3 v1", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK backup to disk/S3 ok", :toolbox_server)
  @runner.run_script_on_set("DB SQLS Norecovery snapshot", :toolbox_server)  
  @runner.run_script_on_set("SQLS CHECK norecovery snapshot ok", :toolbox_server, 1800)  
#  @runner.run_script_on_set("DB SQLS DISABLE SERVER - snapshot, detach and delete volumes v1", :toolbox_server) 

#  @runner.stop_all

  @runner.launch_set(:mirror_servers)
  @runner.wait_for_set(:mirror_servers, "operational")
 
  @runner.check_monitoring
 
  @runner.run_script_on_set("SQLS CHECK principal connected", :principal_mirror_server)
  @runner.run_script_on_set("DNS DNSMadeEasy register IP", :principal_mirror_server)
  @runner.run_script_on_set("SQLS CHECK dns updated", :principal_mirror_server)
  @runner.run_script_on_set("DB SQLS Manual failover", :principal_mirror_server)
  @runner.run_script_on_set("SQLS CHECK failover ok", :principal_mirror_server)
  @runner.run_script_on_set("DB SQLS Switch mirroring off", :principal_mirror_server)
  @runner.run_script_on_set("SQLS CHECK mirroring switched off", :principal_mirror_server)
#  @runner.run_script_on_set("DB SQLS DISABLE SERVER - snapshot, detach and delete volumes v1", :principal_mirror_server)
end
