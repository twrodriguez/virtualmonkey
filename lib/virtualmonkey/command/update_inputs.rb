module VirtualMonkey
  module Command

# monkey update_inputs --common_inputs blah.json --tag unique_name --cloud_variables blah.json
    def self.update_inputs
      @@options = Trollop::options do
        opt :common_inputs, "Paths to common input json files to load and set on all deployments.  Accepts space separated pathnames or one argument per pathname.  Eg. -c config/mysql_inputs.json -c config/other_inputs.json", :type => :strings, :short => '-c'
        opt :cloud_variables, "Path to json file containing common inputs and variables per cloud. See config/cloud_variables.json.example", :type => :strings, :required => false, :short => '-v'
        opt :clouds, "Space-separated list of cloud_ids to use", :type => :integers, :short => '-i'
        opt :tag, "Tag to use as nickname prefix for all deployments.", :type => :string, :required => true, :short => '-t'
      end
      @@dm = DeploymentMonk.new(@@options[:tag])
      if @@options[:clouds]
        @@dm.load_clouds(@@options[:clouds])
      elsif @@options[:cloud_variables]
        @@options[:cloud_variables].each { |cvpath| @@dm.load_cloud_variables(cvpath) }
      end
      if @@options[:common_inputs]
        @@options[:common_inputs].each { |cipath| @@dm.load_common_inputs(cipath) }
      end
      @@dm.update_inputs
      @@dm.set_server_params
    end
  end
end
