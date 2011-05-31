module VirtualMonkey
  module Chef
    def chef_download_once_lookup_scripts
      @servers.each { |s|
        Tag.set(s.href, ["rs_agent_dev:download_cookbooks_once=true"])
#        s.tags += [{"name"=>"rs_agent_dev:download_cookbooks_once=true"}]
#        s.save
      }
    end
  end
end
