set :runner, VirtualMonkey::Runner::MonkeyMetaTroop
set :allow_meta_monkey
set :logs, "console_output.log", "index.html"
set "branch", "beta"
set "troop", File.join("11H2", "base_chef.json")
set "prefix" {
  troop_file = File.join(__FILE__, "..", "config", "troop", @options[:runner_options]["troop"])
  JSON::parse(IO.read(file))["prefix"]
}

before do
  launch_all
  wait_for_all("operational")
  pull_branch
end

test "syntax" do
end

test "troop" do
  run_troop
end

after do
  stop_all
end
