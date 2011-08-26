require 'rubygems'
require 'erb'
require 'fog'
require 'eventmachine'
require 'right_popen'

class GrinderJob
  attr_accessor :status, :output, :logfile, :deployment, :rest_log, :other_logs, :no_resume, :verbose

  def link_to_rightscale
#    i = deployment.href.split(/\//).last
#    d = deployment.href.split(/\./).first.split(/\//).last
#    "https://#{d}.rightscale.com/deployments/#{i}#auditentries"
    deployment.href.gsub(/api\//,"") + "#auditentries"
  end

  # stdout hook for popen3
  def on_read_stdout(data)
    data_ary = data.split("\n")
    data_ary.each_index do |i|
      data_ary[i] = timestamp + data_ary[i]
      $stdout.syswrite("<#{deploy_id}>#{data_ary[i]}\n") if @verbose
    end
    File.open(@logfile, "a") { |f| f.write(data_ary.join("\n") + "\n") }
  end

  # stderr hook for popen3
  def on_read_stderr(data)
    data_ary = data.split("\n")
    data_ary.each_index do |i|
      data_ary[i] = timestamp + data_ary[i]
      $stdout.syswrite("<#{deploy_id}>#{data_ary[i]}\n") if @verbose
    end
    File.open(@logfile, "a") { |f| f.write(data_ary.join("\n") + "\n") }
  end

  def timestamp
    t = Time.now
    "#{t.strftime("[%m/%d/%Y %H:%M:%S.")}%-6d] " % t.usec
  end

  def deploy_id
    @id = deployment.rs_id
  end

  # Could be deprecated...
  def receive_data(data)
    data_ary = data.split("\n")
    data_ary.each_index do |i|
      data_ary[i] = timestamp + data_ary[i]
      $stdout.syswrite("<#{deploy_id}>#{data_ary[i]}\n") if @verbose
    end
    File.open(@logfile, "a") { |f| f.write(data_ary.join("\n") + "\n") }
  end

  # unbind hook for popen3
  def unbind
    @status = get_status.exitstatus
  end

  # on_exit hook for popen3
  def on_exit(status)
    @status = status.exitstatus
  end

  # Launch an asynchronous process
  def run(cmd)
    RightScale.popen3(:command        => cmd,
                      :target         => self,
                      :environment    => {"AWS_ACCESS_KEY_ID" => Fog.credentials[:aws_access_key_id],
                                          "AWS_SECRET_ACCESS_KEY" => Fog.credentials[:aws_secret_access_key],
                                          "REST_CONNECTION_LOG" => @rest_log,
                                          "MONKEY_NO_DEBUG" => "true",
                                          "MONKEY_LOG_BASE_DIR" => File.dirname(@rest_log)},
                      :stdout_handler => :on_read_stdout,
                      :stderr_handler => :on_read_stderr,
                      :exit_handler   => :on_exit)
  end
end

class GrinderMonk
  attr_accessor :jobs
  attr_accessor :options

  def self.combo_feature_name(features)
    File.join(VirtualMonkey::FEATURE_DIR, features.map { |feature| File.basename(feature, ".rb") }.join("_") + ".combo.rb")
  end

  # Runs a grinder test on a single Deployment
  # * deployment<~String> the nickname of the deployment
  # * feature<~String> the feature filename 
  def run_test(deployment, feature, test_ary, other_logs = [])
    new_job = GrinderJob.new
    new_job.logfile = File.join(@log_dir, "#{deployment.nickname}.log")
    new_job.rest_log = File.join(@log_dir, "#{deployment.nickname}.rest_connection.log")
    new_job.other_logs = other_logs.map { |log|
      File.join(@log_dir, "#{deployment.nickname}.#{File.basename(log)}")
    }
    new_job.deployment = deployment
    new_job.verbose = true if @options[:verbose]
    cmd = "bin/grinder -f \"#{feature}\" -d \"#{deployment.nickname}\" -g -l \"#{new_job.logfile}\" -t "
    test_ary.each { |test| cmd += " \"#{test}\" " }
    cmd += " -r " if @options[:no_resume]
    @jobs << new_job
    puts "running #{cmd}"
    new_job.run(cmd)
  end

  def initialize()
    @started_at = Time.now
    @jobs = []
    @passed = []
    @failed = []
    @running = []
    dirname = Time.now.strftime(File.join("%Y", "%m", "%d", "%H-%M-%S"))
    @log_dir = File.join(VirtualMonkey::ROOTDIR, "log", dirname)
    @log_started = dirname
    FileUtils.mkdir_p(@log_dir)
    @feature_dir = File.join(VirtualMonkey::ROOTDIR, 'features')
  end
 
  # runs a feature on an array of deployments
  # * deployments<~Array> array of strings containing the nicknames of the deployments
  # * feature_name<~String> the feature filename 
  def run_tests(deployments,features,set=[])
    features = [features].flatten
    test_cases = features.map_to_h { |feature| VirtualMonkey::TestCase.new(feature, @options) }
    deployment_hsh = {}
    if ENV['MONKEY_PARALLEL_FEATURES']
      raise "Need more deployments than feature files" unless deployments.length > features.length
      dep_clone = deployments.dup
      deps_per_feature = (deployments.length.to_f / features.length.to_f).floor
      deployment_hsh = features.map_to_h { |f|
        dep_clone = dep_clone.shuffle
        dep_clone.slice!(0,deps_per_feature)
      }
    else
      combo_feature = GrinderMonk.combo_feature_name(features)
      File.open(combo_feature, "w") { |f|
        f.write(features.map { |feature| "mixin_feature '#{feature}', :hard_reset" }.join("\n"))
      }
      test_cases[combo_feature] = VirtualMonkey::TestCase.new(combo_feature, @options)
      deployment_hsh = { combo_feature => deployments }
    end

    deployment_hsh.each { |feature,deploy_ary|
      total_keys = test_cases[feature].get_keys
      total_keys = total_keys - (total_keys - set) unless set.nil? || set.empty?
      if ENV['FULL_TEST_PERMUTATION']
        deployment_tests = [total_keys] * deploy_ary.length
      else
        keys_per_dep = (total_keys.length.to_f / deploy_ary.length.to_f).ceil

        deployment_tests = []
        (keys_per_dep * deploy_ary.length).times { |i|
          di = i % deploy_ary.length
          deployment_tests[di] ||= []
          deployment_tests[di] << total_keys[i % total_keys.length]
        }
      end

      deployment_tests.map! { |ary| ary.shuffle } unless ENV['MONKEY_STRICT_TEST_ORDERING']

      deploy_ary.each_with_index { |d,i| 
        run_test(d, feature, deployment_tests[i], test_cases[feature].options[:additional_logs])
      }
    }
  end

  # Print status of jobs. Also watches for jobs that had exit statuses other than 0 or 1
  def watch_and_report
    old_passed = @passed
    old_failed = @failed
    old_running = @running
    old_sum = old_passed.size + old_failed.size + old_running.size
    @passed = @jobs.select { |s| s.status == 0 }
    @failed = @jobs.select { |s| s.status != 0 && s.status != nil }
    @running = @jobs.select { |s| s.status == nil }
    new_sum = @passed.size + @failed.size + @running.size
    puts "#{@passed.size} features passed.  #{@failed.size} features failed.  #{@running.size} features running for #{Time.now - @started_at}"
    if new_sum < old_sum and new_sum < @jobs.size
      puts "WARNING: Jobs Lost! Finding..."
      report_lost_deployments({ :old_passed => old_passed, :passed => @passed,
                                :old_failed => old_failed, :failed => @failed,
                                :old_running => old_running, :running => @running })
    end
    if old_passed != @passed || old_failed != @failed
      status_change_hook
    end
  end

  def status_change_hook
    generate_reports
    if all_done?
      puts "monkey done."
      EM.stop
    end
  end

  def all_done?
    running = @jobs.select { |s| s.status == nil }
    running.size == 0 && @jobs.size > 0
  end

  # Generates monkey reports and uploads to S3
  def generate_reports
    passed = @jobs.select { |s| s.status == 0 }
    failed = @jobs.select { |s| s.status == 1 }
    running = @jobs.select { |s| s.status == nil }
    report_on = @jobs.select { |s| s.status == 0 || s.status == 1 }
    index = ERB.new  File.read(File.join(VirtualMonkey::LIB_DIR, "index.html.erb"))
    bucket_name = (Fog.credentials[:s3_bucket] ? Fog.credentials[:s3_bucket] : "virtual_monkey")

    ## upload to s3
    # setup credentials in ~/.fog
    s3 = Fog::Storage.new(:provider => 'AWS', :aws_access_key_id => Fog.credentials[:aws_access_key_id_test], :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
    if directory = s3.directories.detect { |d| d.key == bucket_name } 
      puts "found directory, re-using"
    else
      directory = s3.directories.create(:key => bucket_name)
    end
    raise 'could not create directory' unless directory
    s3.put_object(bucket_name, "#{@log_started}/index.html", index.result(binding), 'x-amz-acl' => 'public-read', 'Content-Type' => 'text/html')
 
    report_on.each do |j|
      begin
        done = false
        s3.put_object(bucket_name, "#{@log_started}/#{File.basename(j.logfile)}", IO.read(j.logfile), 'Content-Type' => 'text/plain', 'x-amz-acl' => 'public-read')
        s3.put_object(bucket_name, "#{@log_started}/#{File.basename(j.rest_log)}", IO.read(j.rest_log), 'Content-Type' => 'text/plain', 'x-amz-acl' => 'public-read')
        j.other_logs.each { |log|
          if File.exists?(log)
            content = `file -ib #{log}`.split(/;/).first
            s3.put_object(bucket_name, "#{@log_started}/#{File.basename(log)}", IO.read(log), 'x-amz-acl' => 'public-read', 'Content-Type' => content)
          end
        }
        done = true
      rescue Exception => e
        raise e unless e.message =~ /Bad file descriptor|no such file or directory/i
        sleep 1
      end while not done
    end
    
    msg = <<END_OF_MESSAGE
    new results avilable at http://s3.amazonaws.com/#{bucket_name}/#{@log_started}/index.html\n-OR-\nin #{@log_dir}/index.html"
END_OF_MESSAGE
    puts msg
  end
  
  # Prints information on jobs that didn't have an exit code of 0 or 1
  def report_lost_deployments(jobs = {})
    running_change = jobs[:old_running] - jobs[:running]
    passed_change = jobs[:passed] - jobs[:old_passed]
    failed_change = jobs[:failed] - jobs[:old_failed]
    lost_jobs = running_change - passed_change - failed_change
    lost_jobs.each do |j|
      puts "LOST JOB---------------------------------"
      puts "Deployment Name: #{j.deployment.nickname}"
      puts "Status Code: #{j.status}"
      puts "Audit Entries: #{j.link_to_rightscale}"
      puts "Log File: #{j.logfile}"
      puts "Rest_Connection Log File: #{j.rest_log}"
      puts "-----------------------------------------"
    end
  end
end

