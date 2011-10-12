# To use with thin
# thin start -p PORT -R config.ru

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..")))

ENV['ENTRY_COMMAND'] ||= File.basename(__FILE__, ".rb")

require 'rubygems'
require File.join('..', 'web_app.rb')
require 'sinatra'

# disable sinatra's auto-application starting
#disable :run

set :environment, :development #:test, :production

set :sessions, :domain => VirtualMonkey::PUBLIC_HOSTNAME # TODO Configure these cookies to work securely
set :bind, VirtualMonkey::PUBLIC_HOSTNAME
set :port, 443
set :static, false
#set :public_folder, VirtualMonkey::WEB_APP_PUBLIC_DIR

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  settings = YAML::load(IO.read(VirtualMonkey::REST_YAML))
  success = ([username, password] == [settings[:user], settings[:pass]])
  session[:virutalmonkey_id] = rand(1000000)
  success
end

# VirtualMonkey Commands
VirtualMonkey::Command::NonInteractiveCommands.keys.each { |cmd|
  post "#{VirtualMonkey::API_PATH}/#{cmd.to_s}" do
    opts = params.map { |key,val|
      ret = "--#{key}"
      val = val.join(" ") if val.is_a?(Array)
      if val.is_a?(TrueClass)
      elsif val.is_a?(FalseClass)
        ret = nil
      else
        ret += " #{val}"
      end
      ret
    }.compact
    opts << "--yes" unless opts.include?("--yes")
    opts << "--report_metadata" if cmd == "run" || cmd == "troop"

    if VirtualMonkey::daemons.length < VirtualMonkey::max_daemons
      app = Daemons.call(:multiple => true, :backtrace => true) do
        VirtualMonkey::Command.__send__(cmd, *opts)
      end
      VirtualMonkey::daemons << {"daemon" => app,
                                 "command" => cmd,
                                 "options" => opts}

      status 202
      body({"status" => "running"}.to_json)
    else
      VirtualMonkey::daemon_queue << {"command" => cmd, "options" => opts}

      status 202
      body({"status" => "queued"}.to_json)
    end
  end
}

# Other API calls
get "#{VirtualMonkey::API_PATH}/get_data" do
  req_params = JSON.parse(request.body)
  VirtualMonkey::Report::get_data(req_params).to_json
end

get "#{VirtualMonkey::API_PATH}/queue" do
  {
    "max_daemons" => VirtualMonkey::max_daemons,
    "running_daemons" => VirtualMonkey::daemons.map { |h| "#{h["command"]} #{h["options"].join(" ")}" },
    "queued_daemons" => VirtualMonkey::daemon_queue.map { |h| "#{h["command"]} #{h["options"].join(" ")}" }
  }.to_json
end

post "#{VirtualMonkey::API_PATH}/queue" do
  req_params = JSON.parse(request.body)

  # Check Parameters
  req_params.each { |key,val|
    case key
    when "max_daemons"
      if val.is_a?(Integer)
        VirtualMonkey::max_daemons = val
      else
        status 400
        return "Parameter max_daemons takes an Integer value"
      end
    when "stop_daemons"
      # TODO
    end
  }

  status 202
end

# HTML, JS, and CSS
get "/*" do
  IO.read(File.join(VirtualMonkey::WEB_APP_PUBLIC_DIR, *(params[:splat].split(/\//))))
end
