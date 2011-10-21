set :runner, VirtualMonkey::Runner::MonkeyMetaTroop
set :allow_meta_monkey
set :logs, "console_output.log", "index.html"
set "branch", "beta"
set "troops", {"pass" => "monkey_diagnostic_pass.json", "fail" => "monkey_diagnostic_fail.json"}
set "prefix" do
  ret = {}
  @options[:runner_options]["troops"].each { |key,troop|
    file = File.join(VirtualMonkey::TROOP_DIR, troop)
    ret[key] = JSON::parse(IO.read(file))["prefix"]
  }
  ret
end

before do
  launch_all
  wait_for_all("operational")
  pull_branch if @options[:runner_options]["branch"]
  test_syntax_and_dependencies
end

test "troop" do
  run_troop
end

# TODO test operational scripts

after do
  stop_all
end
