#!/usr/bin/env ruby
require 'rubygems'
require 'trollop'
require 'highline/import'
require 'virtualmonkey/command/create'
require 'virtualmonkey/command/destroy'
require 'virtualmonkey/command/run'
require 'virtualmonkey/command/list'
require 'virtualmonkey/command/troop'
require 'virtualmonkey/command/clone'
require 'uri'

module VirtualMonkey
  module Command
    # Parses the initial command string, removing it from ARGV, then runs command.
    def self.go
      @@command = ARGV.shift
      @@global_state_dir = File.join(File.dirname(__FILE__), "..", "..", "test_states")
      @@features_dir = File.join(File.dirname(__FILE__), "..", "..", "features")
      @@cfg_dir = File.join(File.dirname(__FILE__), "..", "..", "config")
      @@cv_dir = File.join(@@cfg_dir, "cloud_variables")
      @@ci_dir = File.join(@@cfg_dir, "common_inputs")

      case @@command
        when "create"
          VirtualMonkey::Command.create
        when "destroy"
          VirtualMonkey::Command.destroy
        when "run"
          VirtualMonkey::Command.run
        when "list"
          VirtualMonkey::Command.list
        when "troop"
          VirtualMonkey::Command.troop
        when "clone"
          VirtualMonkey::Command.clone
        when "help" || "--help" || "-h"
          puts "Help usage: monkey <command> --help"
          puts "Valid commands for monkey: create, destroy, list, run, troop, clone or help"
        else
          STDERR.puts "Invalid command #{@@command}: You need to specify a command for monkey: create, destroy, list, run, troop, clone or help\n"
          exit(1)
      end
    end

    def self.create_logic
      @@dm.variables_for_cloud = JSON::parse(IO.read(@@options[:cloud_variables]))
      @@options[:common_inputs].each { |cipath| @@dm.load_common_inputs(cipath) }
      @@dm.generate_variations(@@options)
    end

    def self.run_logic
      begin
        eval("VirtualMonkey::#{@@options[:terminate]}.new('fgasvgreng243o520sdvnsals')") if @@options[:terminate]
      rescue Exception => e
        unless e.message =~ /Could not find a deployment named/
          puts "WARNING: VirtualMonkey::#{@@options[:terminate]} is not a valid class. Defaulting to SimpleRunner."
          @@options[:terminate] = "SimpleRunner"
        end 
      end

      EM.run {
        @@gm ||= GrinderMonk.new
        @@dm ||= DeploymentMonk.new(@@options[:tag])
        @@do_these ||= @@dm.deployments
        if @@options[:only]
          @@do_these = @@do_these.select { |d| d.nickname =~ /#{@@options[:only]}/ }
        end 

        unless @@options[:no_resume]
          temp = @@do_these.select do |d| 
            File.exist?(File.join(@@global_state_dir, d.nickname, File.basename(@@options[:feature])))
          end 
          @@do_these = temp if temp.length > 0 
        end 

        @@gm.options = @@options
        raise "No deployments matched!" unless @@do_these.length > 0 
        @@do_these.each { |d| say d.nickname }

        unless @@options[:yes] or @@command == "troop"
          confirm = ask("Run tests on these #{@@do_these.length} deployments (y/n)?", lambda { |ans| true if (ans =~ /^[y,Y]{1}/) })
          raise "Aborting." unless confirm
        end

        @@remaining_jobs = @@gm.jobs.dup
        @@do_these.each do |deploy|
          @@gm.run_test(deploy, @@options[:feature])
        end

        watch = EM.add_periodic_timer(10) {
          @@gm.watch_and_report
          if @@gm.all_done?
            watch.cancel
          end
          if @@options[:terminate]
            @@remaining_jobs.each do |job|
              if job.status == 0
                if @@command != "troop" or @@options[:step] =~ /all/
                  destroy_job_logic(job)
                end
              end
            end
          end
        }
      }
    end

    def self.destroy_job_logic(job)
      runner = eval("VirtualMonkey::#{@@options[:terminate]}.new(job.deployment.nickname)")
      puts "Destroying successful deployment: #{runner.deployment.nickname}"
      runner.behavior(:stop_all, false)
      runner.deployment.destroy unless @@options[:no_delete] or @@command =~ /run|clone/
      @@remaining_jobs.delete(job)
      #Release DNS logic
      if runner.respond_to?(:release_dns) and not @@options[:no_delete]
        ["virtualmonkey_shared_resources", "virtualmonkey_awsdns", "virtualmonkey_dyndns"].each { |domain|
          begin
            dns = SharedDns.new(domain)
            raise "Unable to reserve DNS" unless dns.reserve_dns(deploy.href)
            dns.release_dns
          rescue Exception => e
            raise e unless e.message =~ /Unable to reserve DNS/
          end
        }
      end
    end

    def self.destroy_all_logic
      @@dm.deployments.each do |deploy|
	nickname = val = URI.escape(deploy.nickname, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        runner = eval("VirtualMonkey::#{@@options[:terminate]}.new(nickname)")
        runner.behavior(:stop_all, false)
        state_dir = File.join(@@global_state_dir, deploy.nickname)
        if File.directory?(state_dir)
          puts "Deleting state files for #{deploy.nickname}..."
          Dir.new(state_dir).each do |state_file|
            if File.extname(state_file) =~ /((rb)|(feature))/
              File.delete(File.join(state_dir, state_file))
            end 
          end 
          Dir.rmdir(state_dir)
        end 
        #Release DNS logic
        if runner.respond_to?(:release_dns) and not @@options[:no_delete]
          ["virtualmonkey_shared_resources", "virtualmonkey_awsdns", "virtualmonkey_dyndns"].each { |domain|
            begin
              dns = SharedDns.new(domain)
              raise "Unable to reserve DNS" unless dns.reserve_dns(deploy.href)
              dns.release_dns
            rescue Exception => e
              raise e unless e.message =~ /Unable to reserve DNS/
            end
          }
        end
      end 

      @@dm.destroy_all unless @@options[:no_delete]
    end
  end
end
