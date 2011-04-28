some_not_included = true
files = Dir.glob(File.join("lib", "virtualmonkey", "deployment_runners", "**"))
while some_not_included do
  begin
    some_not_included = false
    for f in files do
      some_not_included ||= require f.chomp(".rb")
    end
  rescue Exception => e
    some_not_included = true
    files.push(files.shift)
  end
end
