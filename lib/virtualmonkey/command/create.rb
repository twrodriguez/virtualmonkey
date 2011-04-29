module VirtualMonkey
  module Command

# monkey create --server_template_ids 123,123 --common_inputs blah.json --feature simple.feature --tag unique_name --TBD:filter?
    def self.create
      raise "Aborting" unless VirtualMonkey::Toolbox::api0_1?
      @@options = Trollop::options do
        opt :server_template_ids, "ServerTemplate ids or names to use for creating the deployment.  Use one ID or name per server that you would like to be in the deployment.  Accepts space-separated integers or strings (using quotes to , or one argument per id. Eg. -s 23747 23747", :type => :strings, :required => true, :short => '-s'
        opt :common_inputs, "Paths to common input json files to load and set on all deployments.  Accepts space separated pathnames or one argument per pathname.  Eg. -c config/mysql_inputs.json -c config/other_inputs.json", :type => :strings, :required => true, :short => '-c'
        opt :tag, "Tag to use as nickname prefix for all deployments.", :type => :string, :required => true, :short => '-t'
        opt :cloud_variables, "Path to json files containing common inputs and variables per cloud. See config/cloud_variables.json.example", :type => :strings, :short => '-v'
        opt :clouds, "Space-separated list of cloud_ids to use", :type => :integers, :short => '-i'
        opt :only, "Regex string to use for subselection matching on MCIs to enumerate Eg. --only Ubuntu", :type => :string
        opt :no_spot, "Do not use spot instances"
      end
      raise "Either --cloud_variables or --clouds is required" unless @@options[:cloud_variables] or @@options[:clouds]
      @@dm = DeploymentMonk.new(@@options[:tag], @@options[:server_template_ids])
      create_logic
    end
  end
end
