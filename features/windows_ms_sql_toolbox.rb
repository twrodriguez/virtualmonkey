set :runner, VirtualMonkey::Runner::SimpleWindowsSqlsToolbox

before do
  @runner.stop_all
  @runner.set_test_lineage
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do

  @runner.check_monitoring
  
  @runner.run_script_on_all("EBS Create data and log volumes v1")
  @runner.run_script_on_all("SQLS CHECK volumes created")
  @runner.run_script_on_all("EBS Create backup volume")
  @runner.run_script_on_all("SQLS CHECK backup volume created")
  @runner.run_script_on_all("DB SQLS Configure tempdb")  
  @runner.run_script_on_all("SQLS CHECK tempdb configured")
  @runner.run_script_on_all("DB SQLS Restore from disk/S3 v1")  
  @runner.run_script_on_all("SQLS CHECK restore from disk/S3 ok")
  @runner.run_script_on_all("DB SQLS Set Full Recovery Model")  
  @runner.run_script_on_all("SQLS CHECK full recovery model set")
  @runner.run_script_on_all("DB SQLS Set default backup compression")  
  @runner.run_script_on_all("SQLS CHECK backup compression set")
  @runner.run_script_on_all("DB SQLS Create login v1")  
  @runner.run_script_on_all("SQLS CHECK login created")
  @runner.run_script_on_all("DB SQLS Switch mirroring off")
  @runner.run_script_on_all("SQLS CHECK mirroring switched off")
  @runner.run_script_on_all("DB SQLS Backup to disk/S3 v1")  
  @runner.run_script_on_all("SQLS CHECK backup to disk/S3 ok")
  @runner.run_script_on_all("DB SQLS Norecovery snapshot")  
  @runner.run_script_on_all("SQLS CHECK norecovery snapshot ok")  
  @runner.run_script_on_all("DB SQLS DISABLE SERVER - snapshot, detach and delete volumes")
end
