progress_require('sinatra/base')

module VirtualMonkey
  API_PATH = "/api"
  LOCAL_PORT = 4567
  WEB_APP_PUBLIC_DIR = File.join(VirtualMonkey::WEB_APP_DIR, "virtualmonkey")

  def self.max_daemons
    @@max_daemons ||= 1
  end

  def self.max_daemons=(int)
    @@max_daemons = int if int.is_a?(Integer)
  end

  def self.daemons
    @@daemons ||= []
  end

  def self.daemon_queue
    @@daemon_queue ||= []
  end

  class InternalAPI < Sinatra::Base
    set :sessions, true
    set :bind, 'localhost'
    set :port, VirtualMonkey::LOCAL_PORT

    get "#{API_PATH}/update" do
      VirtualMonkey::Report.update
    end
  end
end
