module VirtualMonkey
  module Report
    # Amazon SimpleDB Connection
    BASE_DOMAIN = "virtualmonkey_test_metadata"
    @@domain = "#{BASE_DOMAIN}_#{Time.now.strftime("%Y_%m")}"
    @@last_month_domain = "#{BASE_DOMAIN}_#{Time.now.year}_#{"%02d" % Time.now.month}"
    @@jobs_domain = "virtualmonkey_jobs"

    def new_sdb_connection
      Fog::AWS::SimpleDB.new()
    end

    def self.update_s3(jobs, log_started)
      def upload_args(bucket, log_started, filename)
        content = `file -ib #{filename}`.split(/;/).first
        [
          bucket,
          "#{log_started}/#{File.basename(filename)}",
          IO.read(filename),
          {'x-amz-acl' => 'public-read', 'Content-Type' => content}
        ]
      end

      # Initialize Variables
      s3 = Fog::Storage.new(:provider => "AWS")
      passed = jobs.select { |s| s.status == 0 }
      failed = jobs.select { |s| s.status == 1 }
      running = jobs.select { |s| s.status == nil }
      report_on = jobs.select { |s| s.status == 0 || s.status == 1 }
      bucket_name = Fog.credentials[:s3_bucket] || "virtual_monkey"

      index = ERB.new(File.read(File.join(VirtualMonkey::LIB_DIR, "index.html.erb")))
      index_html_file = File.join(log_started, "index.html")
      File.open(index_html_file, 'w') { |f| f.write(index.result(binding)) }

      ## upload to s3
      if directory = s3.directories.detect { |d| d.key == bucket_name }
        puts "found directory, re-using"
      else
        directory = s3.directories.create(:key => bucket_name)
      end
      raise 'could not create directory' unless directory

      begin
        s3.put_object(*upload_args(bucket_name, log_started, index_html_file))
      rescue Exception => e
        raise e unless e.message =~ /Bad file descriptor|no such file or directory/i
        sleep 1
        retry
      end
      report_url = "http://s3.amazonaws.com/#{bucket_name}/#{log_started}/index.html"

      report_on.each do |job|
        begin
          [job.logfile, job.rest_log].each { |log|
            s3.put_object(*upload_args(bucket_name, log_started, log))
          }
          ([job.err_log] + j.other_logs).each { |log|
            s3.put_object(*upload_args(bucket_name, log_started, log)) if File.exists?(log)
          }
        rescue Exception => e
          raise e unless e.message =~ /Bad file descriptor|no such file or directory/i
          sleep 1
          retry
        end
      end

      ## Return report url
      return report_url
    end

    def self.update_sdb(jobs)
      ## upload to sdb
      @@sdb ||= new_sdb_connection
      begin
        ensure_domain_exists
        current_items = @@sdb.select("SELECT * from #{@@domain}").body["Items"]
        data = {}
        jobs.each do |job|
          if current_items[job.metadata["job_id"]]
            if current_items[job.metadata["job_id"]]["status"] != job.metadata["status"]
              data[job.metadata["job_id"]] = {"status" => job.metadata["status"]}
            end
          else
            data[job.metadata["job_id"]] = job.metadata
          end
        end
        @@sdb.batch_put_attributes(@@domain, data)
      rescue Excon::Errors::ServiceUnavailable
        warn "Got ServiceUnavailable, retrying..."
        sleep 5
        retry
      rescue Exception => e
        warn "Got #{e.message} from #{e.backtrace.join("\n")}"
      end
    end

    def self.ensure_domain_exists(domain=@@domain)
      # If domain doesn't exist, create domain
      @@sdb ||= new_sdb_connection
      @@sdb.create_domain(domain) unless @@sdb.list_domains.body["Domains"].include?(domain)
    end

=begin
var d1 = [ [0,10], [1,20], [2,80], [3,70], [4,60] ];
var d2 = [ [0,30], [1,25], [2,50], [3,60], [4,95] ];
var d3 = [ [0,50], [1,40], [2,60], [3,95], [4,30] ];

var data = [{
              label: "Goal",
              color: "rgb(0,0,0)",
              data: d1,
              spider: {
                show: true,
                lineWidth: 12
              }
            },
            {
              label: "Complete",
              color: "rgb(0,255,0)",
              data: d3,
              spider: {
                show: true
              }
            }];
=end
    def self.get_data(request_body)
      @@sdb ||= new_sdb_connection
      ret = {"autocomplete_values" => {}, "raw_data" => []}
      domains = [@@domain]
      domains.unshift(@@last_month_domain) if @@sdb.list_domains.body["Domains"].include?(@@last_month_domain)
      domains.each do |domain|
        # TODO Return in the above format
      end
      return ret
    end
  end
end
