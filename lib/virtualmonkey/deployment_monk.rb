require 'rubygems'
require 'rest_connection'

class DeploymentMonk
  attr_accessor :common_inputs
  attr_accessor :variables_for_cloud, :ec2_ssh_keys
  attr_accessor :deployments
  attr_reader :tag

  def from_tag
    variations = Deployment.find_by(:nickname) {|n| n =~ /^#{@tag}/ }
    puts "loading #{variations.size} deployments matching your tag"
    return variations
  end

  def self.list(tag)
    Deployment.find_by(:nickname) {|n| n =~ /^#{tag}/ }.each { |d| puts d.nickname }
  end

  def initialize(tag, server_templates = [], extra_images = [])
    @clouds = []
    @tag = tag
    @deployments = from_tag
    @server_templates = []
    @common_inputs = {}
    @variables_for_cloud = {}
    @ec2_ssh_keys = {}
    raise "Need either populated deployments or passed in server_template ids" if server_templates.empty? && @deployments.empty?
    if server_templates.empty?
      puts "loading server templates from servers in the first deployment"
      @deployments.each { |d| d.reload }
      @deployments.first.servers.each do |s|
        server_templates << s.server_template_href.split(/\//).last.to_i
      end
    end
    server_templates.each do |st|
      if st =~ /[^0-9]/
        sts_found << ServerTemplate.find_by(:nickname) { |n| n =~ /#{st}/ } #ServerTemplate Name was given
        raise "Found more than one ServerTemplate matching '#{st}'." unless sts_found.size == 1
        @server_templates << sts_found.first
      else
        @server_templates << ServerTemplate.find(st.to_i) #ServerTemplate ID was given
      end
    end

    
  end

#mci = MultiCloudImageInternal.find(mci_id)
#mci.multi_cloud_image_cloud_settings.each { |settings| puts settings["cloud_id"] }
#
#mcis = ServerTemplateInternal.new(:href => ServerTemplate.find(90542).href).multi_cloud_images
#mcis.each { |mci| mci["multi_cloud_image_cloud_settings"].each { |setting| puts setting["cloud_id"] } }

  def generate_variations(options = {})
    @image_count = 0
    @server_templates.each do |st|
      new_st = ServerTemplateInternal.new(:href => st.href)
      st.multi_cloud_images = new_st.multi_cloud_images
      @image_count = st.multi_cloud_images.size if st.multi_cloud_images.size > @image_count
      if options[:mci_override] && !options[:mci_override].empty?
        mci = MultiCloudImageInternal.new(:href => options[:mci_override].first)
        mci.reload
        multi_cloud_images = [mci]
      else
        multi_cloud_images = new_st.multi_cloud_images
      end
      multi_cloud_images.each { |mci|
        @clouds.concat( mci["multi_cloud_image_cloud_settings"].map { |s| [ "#{s["cloud_id"]}" ] } )
      }
    end
    if @clouds.flatten!
      @clouds.uniq!
    end
    if options[:mci_override] && !options[:mci_override].empty?
      @image_count = options[:mci_override].size
    end
    @image_count.times do |index|
      @clouds.each do |cloud|
        if @variables_for_cloud[cloud] == nil
          puts "Variables not found for cloud #{cloud}. Skipping..."
          next
        end
        mci_supports_cloud = true
        @server_templates.each do |st|
          new_st = ServerTemplateInternal.new(:href => st.href)
          if options[:mci_override] && !options[:mci_override].empty?
            mci = MultiCloudImageInternal.new(:href => options[:mci_override][index])
	          mci.reload
          elsif new_st.multi_cloud_images[index]
            mci = new_st.multi_cloud_images[index]
          else
            mci = new_st.multi_cloud_images[0]
          end
          mci_check = false
          mci["multi_cloud_image_cloud_settings"].each { |setting|
            mci_check ||= (setting["cloud_id"].to_i == cloud.to_i)
          }
          mci_supports_cloud &&= mci_check
        end
        unless mci_supports_cloud
          puts "MCI doesn't contain an image that supports cloud #{cloud}. Skipping..."
          next
        end
        dep_tempname = "#{@tag}-cloud_#{cloud}-#{rand(1000000)}-"
        dep_image_list = []
        new_deploy = Deployment.create(:nickname => dep_tempname)
        @deployments << new_deploy
        @server_templates.each do |st|
          #Select an MCI to use
          if options[:mci_override] && !options[:mci_override].empty?
            mci = MultiCloudImageInternal.new(:href => options[:mci_override][index])
	    mci.reload
            use_this_image_setting = mci['multi_cloud_image_cloud_settings'].detect { |setting| setting["image_href"].include?("cloud_id=#{cloud}") }
            use_this_image = use_this_image_setting["image_href"]
            use_this_instance_type = use_this_image_setting["aws_instance_type"]
            dep_image_list << MultiCloudImage.find(options[:mci_override][index]).name.gsub(/ /,'_')
          elsif st.multi_cloud_images[index]
            dep_image_list << st.multi_cloud_images[index]['name'].gsub(/ /,'_')
            use_this_image = st.multi_cloud_images[index]['href']
          else
            use_this_image = st.multi_cloud_images[0]['href']
          end
          inputs = []
          unless @ec2_ssh_keys[cloud]
            `export ADD_CLOUD_SSH_KEY=#{cloud}; bash -cex "cd spec; ruby generate_ec2_ssh_keys.rb"`
            @ec2_ssh_keys = JSON::parse(IO.read(File.join("config","cloud_variables","ec2_keys.json")))
          end
          @variables_for_cloud[cloud].merge!(@ec2_ssh_keys[cloud])
          @common_inputs.merge!(@variables_for_cloud[cloud]['parameters'])
          @common_inputs.each do |key,val|
            inputs << { :name => key, :value => val }
          end
          #Set Server Creation Parameters
          server_params = { :nickname => "#{@tag}-tempserver-#{rand(1000000)}-#{st.nickname}", 
                            :deployment_href => new_deploy.href.dup, 
                            :server_template_href => st.href.dup, 
                            :cloud_id => cloud,
                            :inputs => inputs,
                            :mci_href => use_this_image
                            #:ec2_image_href => image['image_href'], 
                            #:instance_type => image['aws_instance_type'] 
                          }
          # If overriding the multicloudimage need to specify the ec2 image href because you can't set an MCI that's not in the ServerTemplate
          if options[:mci_override] && !options[:mci_override].empty?
            server_params.reject! {|k,v| k == :mci_href}
            server_params[:ec2_image_href] = use_this_image
            server_params[:instance_type] = use_this_instance_type
          end

          #This rescue block can be removed after the VM ServerTemplate defaults to multicloud rest_connection
          begin
            server = ServerInterface.new(cloud).create(server_params.merge(@variables_for_cloud[cloud]))
          rescue Exception => e
            puts "Got exception: #{e.message}"
            puts "Backtrace: #{e.backtrace.join("\n")}"
          end
          #AWS Cloud-specific Code XXX LEGACY XXX
          if cloud.to_i < 10
            server = Server.create(server_params.merge(@variables_for_cloud[cloud])) unless server
            # since the create call does not set the parameters, we need to set them separate
            set_inputs(server, @variables_for_cloud[cloud]['parameters'])
            # uses a special internal call for setting the MCI on the server
            sint = ServerInternal.new(:href => server.href)
            sint.set_multi_cloud_image(use_this_image) unless options[:mci_override] && !options[:mci_override].empty?

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
          new_deploy.nickname = dep_tempname + dep_image_list.uniq.join("_AND_")
          new_deploy.save
          set_inputs(new_deploy, @common_inputs)
        end
      end
    end
  end

  def load_common_inputs(file)
    @common_inputs.merge! JSON.parse(IO.read(file))
  end

  def load_cloud_variables(file)
    @variables_for_cloud.merge! JSON.parse(IO.read(file))
  end

  def update_inputs
    @deployments.each do |d|
      if d.cloud_id
        @common_inputs.merge!(@variables_for_cloud[d.cloud_id]['parameters']) if @variables_for_cloud[d.cloud_id]
      end
      set_inputs(d, @common_inputs)
      d.servers.each { |s|
        cv_inputs = (@variables_for_cloud[s.cloud_id] ? @variables_for_cloud[s.cloud_id]['parameters'] : {})
        set_inputs(s, @common_inputs.merge(cv_inputs))
      }
    end
  end

  def set_inputs(obj, inputs)
    if obj.respond_to?(:set_inputs)
      obj.set_inputs(inputs)
    else
      inputs.each { |key,val| obj.set_input(key,val) }
    end
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

  def get_deployments
    deployments = []
    @deployments.each { |v| deployments << v.nickname }
    deployments 
  end

end
