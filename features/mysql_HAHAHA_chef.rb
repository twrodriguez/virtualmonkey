set :runner, VirtualMonkey::Runner::MysqlChef

hard_reset do
  stop_all
end

before do
  set_variation_lineage
  set_variation_container
  setup_dns("dnsmadeeasy_new") # dnsmadeeasy
  set_variation_dnschoice("text:DNSMadeEasy") # set variation choice
  launch_all
  wait_for_all("operational")
  disable_db_reconverge
  create_monkey_table
end

test "default" do
  run_chef_promotion_operations
  run_chef_checks
#  check_monitoring
#  check_mysql_monitoring
  run_HA_reboot_operations
end

