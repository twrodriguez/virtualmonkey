require 'rubygems'
require 'rest_connection'
require 'pp'

class DeploymentMonk
  attr_accessor :common_inputs
  attr_accessor :deployments

  # Returns an Array of Deployment objects whose nicknames start with @prefix
  def from_prefix
    variations = Deployment.find_by_tags("info:prefix=#{@prefix}")
    puts "loading #{variations.size} deployments matching your prefix"
    return variations
  end

  # Lists the nicknames of Array of Deployment objects whose nicknames start with prefix
  def self.list(prefix, verbose = false)
    deployments = Deployment.find_by_tags("info:prefix=#{@prefix}")
    if verbose
      pp deployments.map { |d| { d.nickname => d.servers.map { |s| s.state } } }
    else
      pp deployments.map { |d| d.nickname }
    end
  end

  # Lists the nicknames of Array of Deployment objects whose nicknames start with @prefix
  def list(verbose = false)
    if verbose
      pp @deployments.map { |d| { d.nickname => d.servers.map { |s| s.state } } }
    else
      pp @deployments.map { |d| d.nickname }
    end
  end

  def initialize(prefix, server_templates = [], extra_images = [], allow_meta_monkey = false, single_deployment = false)
    @clouds = []
    @single_deployment = single_deployment
    @prefix = prefix
    @deployments = from_prefix
    @server_templates = []
    @common_inputs = {}
    @variables_for_cloud = {}
    @ssh_keys, @security_groups, @datacenters = {}, {}, {}
    #
    # mci.href => [ st.href, st.href ]
    #
    @multi_cloud_images = {}
    #
    # order => { st.href => mci }
    #
    @mci_order = {}
    puts "single_deployment: true" if @single_deployment
    raise "Need either populated deployments or passed in server_template ids" if server_templates.empty? && @deployments.empty?

    # Get list of unique server_template ids
    if server_templates.empty?
      puts "loading server templates from all deployments"
      @deployments.each { |d|
        d.reload
        d.servers_no_reload.each { |s|
          server_templates << s.server_template_href.split(/\//).last.to_i
        }
      }
      server_templates.uniq!
    end

    # Load ServerTemplate objects from names/ids
    server_templates.each do |st|
      if st =~ /[^0-9]/ #ServerTemplate Name was given
        sts_found << ServerTemplate.find_by(:nickname) { |n| n =~ /#{st}/ }
        raise "Found more than one ServerTemplate matching '#{st}'." unless sts_found.size == 1
        st = sts_found.first
      else #ServerTemplate ID was given
        st = ServerTemplate.find(st.to_i)
      end
      # Do not allow Servers using the VirtualMonkey ServerTemplate to be subject to monkey code
      unless allow_meta_monkey
        raise "ABORTING: VirtualMonkey has been found in a deployment." if st.nickname =~ /virtual *monkey/i
      end
      @server_templates << st if allow_meta_monkey or st.nickname !~ /virtual *monkey/i
    end
    raise "Error: To launch a single deployment a maximum of one server template is allowed " if ((@server_templates.length > 1) && @single_deployment)
  end

  def mci_list(options, st)
    if options[:use_mci] && !options[:use_mci].empty?
        mci = MultiCloudImage.new("href" => options[:use_mci].first)
        mci.reload
        mci.find_and_flatten_settings
        multi_cloud_images = [mci]
    elsif options[:only]
      multi_cloud_images = st.multi_cloud_images.select { |mci| mci['name'] =~ /#{options[:only]}/ }
      raise "No MCI on ServerTemplate '#{st.nickname}' matches regex /#{options[:only]}/" if multi_cloud_images.empty?
    else
      multi_cloud_images = st.multi_cloud_images
    end
    raise "No MCIs found on ServerTemplate '#{st.nickname}'!" if multi_cloud_images.empty?
    multi_cloud_images
  end

  def generate_variations(options = {})
    # Count the max number of images that we can select from (@image_count)
    # Get list of supported clouds (@clouds)
    dep_image_names = nil  # This variable holds the names of the images in the deployment
#    @image_count = 0
    @server_templates.each do |st|
      multi_cloud_images = mci_list(options, st)
#      @image_count = multi_cloud_images.size if multi_cloud_images.size > @image_count
      multi_cloud_images.each do |mci|
        @clouds += mci.supported_cloud_ids
        @multi_cloud_images[mci.href] ||= { :mci => mci, :st_ary => [] }
        next if @multi_cloud_images[mci.href][:st_ary].include?(st.href)
        @multi_cloud_images[mci.href][:st_ary] << st.href
      end
    end
    @clouds.flatten!
    @clouds.compact!
    @clouds.uniq!
    @clouds.map! { |m| m.to_s }
    @image_count = @multi_cloud_images.length
    raise "The selected MCIs don't support any clouds!" if @clouds.empty?
    #
    # Sort the MCI's so the same are created together
    #
    start = 0
    mci_map_1 = [] # Array of Hashes
    mci_map_2 = [] # Array of Arrays
    mci_map_3 = [] # Table
    @multi_cloud_images.each { |mci_href,hsh| mci_map_1 << hsh }
    mci_map_1.sort! { |a,b| b[:st_ary].length <=> a[:st_ary].length } # Descending order
    mci_map_2 = mci_map_1.map { |hsh| hsh[:st_ary] }
    mci_map_2.each_with_index { |st_ary,index|
      mci_map_3[index] ||= []
      @server_templates.each { |st|
        mci_map_3[index] << (st_ary.include?(st.href) ? mci_map_1[index][:mci] : nil)
      }
    }
    mci_map_3.transpose.each_with_index { |mci_ary,st_index|
      st_href = @server_templates[st_index].href
      mci_ary.each_with_index { |mci,order_index|
        if mci
          @mci_order[order_index] ||= {}
          @mci_order[order_index][st_href] = mci
        end
      }
    }
    
    dep_tempname = ""
    new_deploy = nil
    nick_name_holder = [] # this variable is used when we want to create a single deployment and we use it to name the deployment properly 
    deployment_created = false # this variable is used to control creating a single deployment 
    @image_count.times do |index|
      @clouds.each do |cloud|

        # Skip if the cloud hasn't been specified
        if @variables_for_cloud[cloud] == nil
          puts "Variables not found for cloud #{cloud}. Skipping..."
          next
        end

        # Check the candidate MCI or Skip if the selected MCI doesn't support the cloud
        mci_supports_cloud = true
        @server_templates.each do |st|
          if @mci_order[index][st.href]
            mci = @mci_order[index][st.href]
          else
            pair = @mci_order.detect { |idx,st_hash| st_hash[st.href] && st_hash[st.href].supported_cloud_ids.include?(cloud.to_i) }
            pair ||= @mci_order.detect { |idx,st_hash| st_hash[st.href] }
            mci = @mci_order[pair.first][st.href]
          end
          mci_supports_cloud &&= mci.supported_cloud_ids.include?(cloud.to_i)
        end
        unless mci_supports_cloud
          puts "MCI doesn't contain an image that supports cloud #{cloud}. Skipping..."
          next
        end

        # Create Deployment for this MCI and cloud
        if @single_deployment && !deployment_created
          dep_tempname = "#{@prefix}-cloud_#{cloud}-#{rand(1000000)}-"
          dep_tempname = "#{@prefix}-cloud_multicloud-#{rand(1000000)}-" if @clouds.length > 1
          new_deploy = Deployment.create(:nickname => dep_tempname)
          new_deploy.set_info_tags("prefix" => @prefix)
          @deployments << new_deploy
          deployment_created = true
        elsif !@single_deployment
          dep_tempname = "#{@prefix}-cloud_#{cloud}-#{rand(1000000)}-"
          new_deploy = Deployment.create(:nickname => dep_tempname)
          new_deploy.set_info_tags("prefix" => @prefix)
          @deployments << new_deploy
        end

        dep_image_list = []
        @server_templates.each do |st|
          nick_name_holder << st.nickname.gsub(/ /,'_')  ## place the nickname into the array
          #Select an MCI to use
          if @mci_order[index][st.href]
            mci = @mci_order[index][st.href]
          else
            pair = @mci_order.detect { |idx,st_hash| st_hash[st.href] && st_hash[st.href].supported_cloud_ids.include?(cloud.to_i) }
            pair ||= @mci_order.detect { |idx,st_hash| st_hash[st.href] }
            mci = @mci_order[pair.first][st.href]
          end
          dep_image_list << dep_image_names = mci.name.gsub(/ /,'_')
          use_this_image = mci.href

          # Load Cloud Variables from all_clouds.json
          load_vars_for_cloud(cloud)

          # Merge cloud_var parameters OVER common_inputs
          inputs = []
          @common_inputs.deep_merge(@variables_for_cloud[cloud]['parameters']).each do |key,val|
            inputs << { "name" => key, "value" => val }
          end


          #Set Server Creation Parameters
          serv_name = "#{@prefix[0...2]}-#{rand(10000)}-#{st.nickname}-#{dep_image_names}" if @single_deployment
          serv_name = "#{@prefix[0...2]}-#{rand(10000)}-#{st.nickname}" unless @single_deployment
          serv_name = "#{@prefix[0...2]}-#{rand(100)}" if cloud.to_s == "232"
          server_params = { "nickname" => serv_name,
                            "deployment_href" => new_deploy.href.dup,
                            "server_template_href" => st.href.dup,
                            "cloud_id" => cloud,
                            "inputs" => inputs,
                            "mci_href" => use_this_image
                            #"ec2_image_href" => image['image_href'],
                            #"instance_type" => image['aws_instance_type']
                          }

          # For non-ec2 clouds we should pick an instance_type
          if cloud.to_i > 10
            i_types = McInstanceType.find_all(cloud)
            select_itype = i_types[i_types.length / 2]
            server_params["instance_type_href"] = select_itype.href
          end

          # If overriding the multicloudimage need to specify the ec2 image href because you can't set an MCI that's not in the ServerTemplate
          if options[:use_mci] && !options[:use_mci].empty?
            server_params.reject! {|k,v| k == "mci_href"}
            use_this_image_setting = mci_list(options, st).first['multi_cloud_image_cloud_settings'].detect { |setting|
              if setting.is_a?(MultiCloudImageCloudSettingInternal)
                ret = (setting.cloud_id == cloud.to_i)
              elsif setting.is_a?(McMultiCloudImageSetting)
                ret = setting.cloud.include?("clouds/#{cloud}")
              end
              ret
            }
            if cloud.to_i < 10
              server_params["ec2_image_href"] = use_this_image_setting["image_href"]
              server_params["instance_type"] = use_this_image_setting["aws_instance_type"]
            else
              server_params["image_href"] = use_this_image_setting.image
              server_params["instance_type_href"] = use_this_image_setting.instance_type
            end
          end

          begin
            server = ServerInterface.new(cloud).create(server_params.deep_merge(@variables_for_cloud[cloud]))
          rescue Exception => e
            msg = "#\n# GOT EXCEPTION: #{e.message}\n#\n"
            STDERR.print(msg)
            next
          end

          # AWS Cloud-specific Code XXX LEGACY XXX
          if cloud.to_i < 10
            # since the create call does not set the parameters, we need to set them separate
            server.set_inputs(@variables_for_cloud[cloud]['parameters'])

            # WHY WE NEED THIS? create maybe already does this 
            # uses a special internal call for setting the MCI on the server
            sint = ServerInternal.new(:href => server.href)
            sint.set_multi_cloud_image(use_this_image) unless options[:use_mci] && !options[:use_mci].empty?

            # finally, set the spot price
            unless options[:no_spot]
              server.reload
              server.settings
              if server.ec2_instance_type =~ /small/ 
                server.max_spot_price = "0.085"
              elsif server.ec2_instance_type =~ /large/
                server.max_spot_price = "0.38"
              end
              server.pricing = "spot"
              server.parameters = {}
              server.save
            end
          end

          # Add image names to the deployment nickname
          new_deploy.nickname = dep_tempname + dep_image_list.uniq.join("_AND_")
          new_deploy.save

          # Set the inputs at the deployment level
          new_deploy.set_inputs(@common_inputs.deep_merge(@variables_for_cloud[cloud]['parameters']))
        end
      end
    end
    if @single_deployment
      new_deploy.nickname = dep_tempname + nick_name_holder.uniq.join("_AND_") + "-ALL_IN_ONE"
      new_deploy.save
    end
  end

  def load_common_inputs(file)
    @common_inputs.deep_merge! JSON.parse(IO.read(file))
  end

  def load_cloud_variables(file)
    @variables_for_cloud.deep_merge! JSON.parse(IO.read(file))
  end

  def load_clouds(cloud_ids)
    VirtualMonkey::Toolbox::populate_all_cloud_vars(:force)
    all_clouds = JSON::parse(IO.read(File.join(VirtualMonkey::CLOUD_VAR_DIR, "all_clouds.json")))
    cloud_ids.each { |id| @variables_for_cloud.deep_merge!(id.to_s => all_clouds[id.to_s]) }
  end

  def update_inputs
    @deployments.each do |d|
      c_inputs = @common_inputs.dup

      # Set inputs at the Deployment level
      # If deployment has the string "-cloud_#-", then collect inputs from cloud_vars
      if d.cloud_id and load_vars_for_cloud(d.cloud_id)
        d.set_inputs(c_inputs.deep_merge(@variables_for_cloud[d.cloud_id.to_s]['parameters']))
      else
        d.set_inputs(c_inputs)
      end

      # Set inputs at the Server level
      d.servers.each { |s|
        cid = VirtualMonkey::Toolbox::determine_cloud_id(s).to_s
        cv_inputs = (load_vars_for_cloud(cid) ? @variables_for_cloud[cid]['parameters'] : {})
        s.set_inputs(c_inputs.deep_merge(cv_inputs))
      }
    end
  end

  def load_vars_for_cloud(cloud)
    cloud = cloud.to_s
    return nil unless @variables_for_cloud[cloud]
    unless @ssh_keys[cloud] and @ssh_keys[cloud] != {}
      VirtualMonkey::Toolbox::generate_ssh_keys(cloud)
      @ssh_keys = JSON::parse(IO.read(File.join(VirtualMonkey::CLOUD_VAR_DIR, "ssh_keys.json")))
    end
    unless @security_groups[cloud] and @security_groups[cloud] != {}
      VirtualMonkey::Toolbox::populate_security_groups(cloud)
      @security_groups = JSON::parse(IO.read(File.join(VirtualMonkey::CLOUD_VAR_DIR, "security_groups.json")))
    end
    unless @datacenters[cloud] and @datacenters[cloud] != {}
      VirtualMonkey::Toolbox::populate_datacenters(cloud)
      @datacenters = JSON::parse(IO.read(File.join(VirtualMonkey::CLOUD_VAR_DIR, "datacenters.json")))
    end
    @variables_for_cloud[cloud].deep_merge!(@ssh_keys[cloud])
    @variables_for_cloud[cloud].deep_merge!(@security_groups[cloud])
    @variables_for_cloud[cloud].deep_merge!(@datacenters[cloud])
    true
  end

  def destroy_all
    @deployments.each { |v|
      v.servers_no_reload.each { |s|
        s.wait_for_state("stopped")
      }
      v.destroy
    }
    @deployments = []
  end

  def set_server_params
    @deployments.each do |d|
      d.servers.each { |s|
        cid = VirtualMonkey::Toolbox::determine_cloud_id(s).to_s
        s.update(@variables_for_cloud[cid]) if load_vars_for_cloud(cid)
      }
    end
  end

end
