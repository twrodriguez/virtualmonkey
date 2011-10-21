set :runner, VirtualMonkey::Runner::MonkeyDiagnostic
#set "branch", "beta"

hard_reset do
  sleep 1
end

before do
  pull_branch
end

before "no-test a", "diagnostic" do
  sleep 1
end

test "no-op" do
  sleep 1
end

after "no-test b", "diagnostic" do
  sleep 1
end

test "diagnostic" do
  run_self_diagnostic
end

after do
  cleanup_branch
end
