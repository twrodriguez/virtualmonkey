class MessageCheck
  attr_accessor :logfile

  WHITELIST = "whitelist"
  BLACKLIST = "blacklist"
  NEEDLIST = "needlist"
  LISTS = [WHITELIST, BLACKLIST, NEEDLIST]

  # @db = { "whitelist": {
  #           "/var/log/messages": [
  #               {"st_rgx": ".*", "msg_rgx": "..."},
  #               {"st_rgx": ".*", "msg_rgx": "..."},
  #               {"st_rgx": ".*", "msg_rgx": "..."}
  #           ]
  #           "/var/log/mysql.err": [
  #               {"st_rgx": ".*", "msg_rgx": "..."}
  #           ]
  #         }
  #         "blacklist": ...
  #       }

  def initialize(lists, strict=false)
#    @sdb = Fog::AWS::SimpleDB.new(:aws_access_key_id => Fog.credentials[:aws_access_key_id_test],
#                                  :aws_secret_access_key => Fog.credentials[:aws_secret_access_key_test])
#    domain_list = @sdb.list_domains.body['Domains']
    @db = {}
    @strict = strict
    @logfile = "/var/log/messages"
    load_lists(lists)
  end

  def logs_to_check(server_templates)
    ret = {}
    server_templates.each do |st|
      LISTS.each { |list|
        @db[list].each do |logfile,entries|
          entries.each { |entry|
            if st.nickname =~ /#{entry['st_rgx']}/
              ret[st.href] ||= []
              ret[st.href] << logfile
            end
          }
        end
      }
    end
    ret.each { |k,v| ret[k].uniq! }
    return ret
  end

  def add_to_list(list, logfile, st_rgx, msg_rgx)
    # Do a union with existing lists to abstract which server templates should match
    entry_to_be = {'st_rgx' => st_rgx, 'msg_rgx' => msg_rgx}
    @db[list][logfile].each { |db_entry|
      if db_entry['msg_rgx'] == msg_rgx
        entry_to_be['st_rgx'] = lcs(db_entry['st_rgx'], entry_to_be['st_rgx'])
      end
    }
    @db[list][logfile].reject! { |db_entry| db_entry['msg_rgx'] == msg_rgx }
    @db[list][logfile] << entry_to_be
  end

  def load_lists(lists = {})
    LISTS.each { |l|
      @db[l] = JSON::parse(IO.read(File.join("config", "lists", "#{l}.json")))
      if lists[l]
        @db[l] ||= {}
        lists[l].each { |logfile,entries|
          @db[l][logfile] ||= []
          entries.each do |entry|
            add_to_list(l, logfile, entry['st_rgx'], entry['msg_rgx']) unless @db[l][logfile].include?(entry)
          end
        }
      end
    }
  end

  def save_db
    LISTS.each { |list|
      list_out = @db[list].to_json(:indent => "  ", :object_nl => "\n", :array_nl => "\n")
      File.open(File.join("config", "lists", "#{list}.json"), "w") { |f| f.write(list_out) }
    }
  end

  def match?(msg, st_name, list)
    @db[list][@logfile].each { |st_rgx,msg_rgx|
      return true if msg =~ /#{msg_rgx}/i and st_name =~ /#{st_rgx}/i
    }
    return false
  end

  def needlist_check(match_list, st_name)
    return [] unless @db[NEEDLIST] and @db[NEEDLIST][@logfile] and @db[NEEDLIST][@logfile].length > 0
    ret_list = @db[NEEDLIST].dup
    ret_list.reject! { |st_rgx,msg_rgx| st_name !~ /#{st_rgx}/i }
    match_list.each { |msg|
      ret_list.reject! { |st_rgx,msg_rgx| msg =~ /#{msg_rgx}/i }
    }
    return ret_list
  end

  def check_messages(object, interactive = false, log_file = @logfile)
    @logfile = log_file
    print_msg = ""
    if object.is_a?(Array)
      object.each { |i| print_msg += check_messages(i, interactive) + "\n" }
    elsif object.is_a?(Deployment)
      print_msg += "Checking #{@logfile} in Deployment #{object.nickname}...\n"
      object.servers_no_reload.each { |s| print_msg += check_messages(s, interactive) + "\n" }
    elsif object.is_a?(Server)
      print_msg += "Checking #{@logfile} for Server #{object.nickname}...\n"
      messages = object.spot_check_command("cat #{@logfile}")[:output].split("\n")
      st = ServerTemplate.find(object.server_template_href)
      # needlist
      n_msg_start = "ERROR: NEEDLIST entry didn't match any messages:"
      need_disparity = needlist_check(messages, st.nickname)
      need_disparity.each { |st_rgx,msg_rgx| print_msg += "#{n_msg_start} [#{st_rgx}, #{msg_rgx}]\n" }
      # blacklist
      b_msg_start = "ERROR: BLACKLIST entry matched:"
      black_matches = messages.select { |line| match?(line, st.nickname, BLACKLIST) }
      # whitelist
      w_msg_start = "WARNING: WHITELIST entry matched:"
      if black_matches.length > 0 and not @strict
        white_matches = black_matches.select { |line| match?(line, st.nickname, WHITELIST) }
        white_matches.each { |msg| print_msg += "#{w_msg_start} #{msg}\n" }
        (black_matches - white_matches).each { |msg| print_msg += "#{b_msg_start} #{msg}\n" }
      else
        black_matches.each { |msg|
          print_msg += "#{b_msg_start} #{msg}\n"
          print_msg += "NOTE: WHITELIST has entry for previous message\n" if match?(msg, st.nickname, WHITELIST)
        }
      end

      if interactive
        black_matches.each { |msg|
          terminal_width = `stty size`.split(" ").last.to_i
          puts "#{"*" * terminal_width}\n#{msg}\n#{"*" * terminal_width}"
          case ask("(B)lacklist, (W)hitelist, (N)eedlist, or (I)gnore?")
          when /^[b,B]/
            puts "Adding to blacklist..."
            message_regex = ask("Enter a regular expression for matching the above line:")
            add_to_list(BLACKLIST, @logfile, st.nickname, message_regex)
          when /^[w,W]/
            puts "Adding to whitelist..."
            message_regex = ask("Enter a regular expression for matching the above line:")
            add_to_list(WHITELIST, @logfile, st.nickname, message_regex)
          when /^[n,N]/
            puts "Adding to needlist..."
            message_regex = ask("Enter a regular expression for matching the above line:")
            add_to_list(NEEDLIST, @logfile, st.nickname, message_regex)
          else
            puts "Ignoring..."
          end
        }
        save_db
      end
    else
      raise "check_messages takes either Deployment or Server objects!"
    end
    return print_msg
  end

  # Longest Common Subsequence
  def lcs(first, second) #Not a perfect solution...watch out for '\' and (".*a.+b.*", "a\000bgoo") -> ".*a\000b.*"
    a, b = first, second
    a = first.split(/\.(\*|\+)/).join("\000") if first =~ /\.(\*|\+)/
    b = second.split(/\.(\*|\+)/).join("\000") if second =~ /\.(\*|\+)/
    lengths = Array.new(a.size+1) { Array.new(b.size+1) { 0 } }
    # row 0 and column 0 are initialized to 0 already
    a.split('').each_with_index { |x, i|
      b.split('').each_with_index { |y, j|
        if x == y
          lengths[i+1][j+1] = lengths[i][j] + 1
        else
          lengths[i+1][j+1] = [lengths[i+1][j], lengths[i][j+1]].max
        end
      }
    }
    # read the substring out from the matrix
    result = "*."
    x, y = a.size, b.size
    previous_found = false
    while x != 0 and y != 0
      if lengths[x][y] == lengths[x-1][y]
        x -= 1
        if previous_found
          result += "+." #result will be reversed later
          previoud_found = false
        end
      elsif lengths[x][y] == lengths[x][y-1]
        y -= 1
        if previous_found
          result += "+." #result will be reversed later
          previoud_found = false
        end
      else
        # assert a[x-1] == b[y-1]
        result << a[x-1]
        x -= 1
        y -= 1
        previoud_found = true
      end
    end
    result << "*."
    result.reverse
  end
end
