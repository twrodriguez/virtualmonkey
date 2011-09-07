set :runner, VirtualMonkey::Runner::SimpleWindowsSqlsToolbox

before do
  @runner.stop_all
  @runner.set_test_lineage
  @runner.launch_all
  @runner.wait_for_all("operational")
end

test "default" do
  @runner.run_script_on_set("EBS Create Data and Log volumes")
  @runner.run_script_on_set("SQLS CHECK volumes created")
  @runner.run_script_on_set("EBS Create Backup volume")
  @runner.run_script_on_set("SQLS CHECK backup volume created")
  @runner.run_script_on_set("DB SQLS Configure TempDB")  
  @runner.run_script_on_set("SQLS CHECK tempdb configured")
  @runner.run_script_on_set("DB SQLS Restore from disk/S3")  
  @runner.run_script_on_set("SQLS CHECK restore from disk/S3 ok")
  @runner.run_script_on_set("DB SQLS Set Full Recovery Model")  
  @runner.run_script_on_set("SQLS CHECK full recovery model set")
  @runner.run_script_on_set("DB SQLS Set default backup compression")  
  @runner.run_script_on_set("SQLS CHECK backup compression set")
  @runner.run_script_on_set("DB SQLS Create login")  
  @runner.run_script_on_set("SQLS CHECK login created")
  @runner.run_script_on_set("DB SQLS Switch mirroring off")
  @runner.run_script_on_set("SQLS CHECK mirroring switched off")
  @runner.run_script_on_set("DB SQLS Backup to disk/S3")  
  @runner.run_script_on_set("SQLS CHECK backup to disk/S3 ok")
  @runner.run_script_on_set("DB SQLS Norecovery snapshot")  
  @runner.run_script_on_set("SQLS CHECK norecovery snapshot ok")  
end
