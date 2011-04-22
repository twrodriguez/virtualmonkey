# Author: Lakhwinder Singh (luke) luke@rightscale.com
# Date  : April 15, 2011

ENV['REST_CONNECTION_LOG'] = "/dev/null"
require 'rubygems'
require 'json'
require 'rest_connection'

all_files = `find ./config/troop`.split("\n")
all_files.reject! { |f| f !~ /json$/ }

@hsh = []


# print the first occurence of the this is line after the executing line
def print_thenis_line(arrayof_inputfile, line_counter)

  print_line = ""
  while(line_counter > -1 && (print_line =~ /(Given)|(Should)|(Then)|(When)/i) == nil) do
    print_line = arrayof_inputfile[line_counter]
    line_counter = line_counter - 1
  end

  return print_line
end


def print_comments(filename)
  arrayof_inputfile = Array.new
  line_counter = -1
  aFile = File.open(filename,"r")
        
  ret = ""
  while(line = aFile.gets)
    unless line =~ /^[ \t]*#/ or line =~ /^[ \t]*$/
      ret += print_thenis_line(arrayof_inputfile,line_counter)
    end
    line_counter +=1       # increment the line counter
    arrayof_inputfile.push(line) #append the given line to the array
  end
  aFile.close
  return ret
end


def open_json_files(filename)

  troop = {}
  troop["name"] = filename.split(File::SEPARATOR).last

  line = File.read(filename);# one line code to read a file and place it into a string
  
  #  check if the old cucumber feature file is in use
  old_featurefile = line.include?".feature" 
  
  # if the feature was not used by cucumber.... so it has been updated
  if(!old_featurefile)


           # parse the JSON file into a hash
     json_hash = JSON.parse(line)
                

     #retrieve the serverteplate ids from the JSON file
     server_templateids = json_hash['server_template_ids']


     troop["server_templates"] = []
       # print the nickname from the server template ids
     server_templateids.each do |st| 
      begin
      
        troop["server_templates"] << ServerTemplate.find(st.to_i).nickname
        rescue Exception => e
         if e.message =~ /RecordNotFound/  # handle the exception
          print "********************One of the servertemplates nolonger exists ************************ \n"
          return; # exit the function after the exeception
         else
          print "\n exception" + e.message + "\n"
          raise e # raise the exception 
          return;  # exit the function after exception 
         end    
        
      end
     end
          
    # hash out the feature files
    feature_filenames = json_hash['feature'] 
    troop["feature_tests"] = {}

    number_of_featurefiles = 1; # assume the returned hash is not an array
    
    # check if the returned feature is an array and out the numeber_of_featurefiles variable 
    if(feature_filenames.is_a?(Array))
      number_of_featurefiles = feature_filenames.length
     end
    
    # print out the comments to the functions that are being executed
    for featurefile_counter in 0 ... number_of_featurefiles
      # add the path  of the feature file to its name
      
      if(number_of_featurefiles > 1)
        filename = %x[find -name #{feature_filenames[featurefile_counter]}].strip  
      else
        filename = %x[find -name #{feature_filenames}].strip
      end

       #filename = "/root/newmonkey_luke/features/"+ feature_filenames
          
      # call this method so we can print the comments
      steps = print_comments(filename);
      troop["feature_tests"][filename.split(File::SEPARATOR).last] = steps.split("\n")
    end     
  end               
  return troop
end

# Iterate through all troop files  the file using a for loop
for file_counter in 0 ... all_files.length
  
  #print all_files[file_counter],"\n";
  @hsh << open_json_files(all_files[file_counter])

 end

File.open("output.json", "w") { |f| f.write(@hsh.to_json(:indent => "  ", :object_nl => "\n", :array_nl => "\n")) }
