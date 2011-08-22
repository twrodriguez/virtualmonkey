module VirtualMonkey
  class TestCase
    attr_accessor :options

    def initialize(file, options = {})
      @options = {}
      @before = {} 
      @test = {}
      @after = {}
      @options = options
      @tests_to_resume = nil
      @options[:additional_logs] = []
      @options[:runner_options] = {}
      @runner = nil
      ruby = IO.read(file)
      eval(ruby)
      self
    end

    def get_keys
      @test.keys
    end

    def check_for_resume
      # Should we resume?
      test_states = VirtualMonkey::TEST_STATE_DIR
      state_dir = File.join(test_states, @options[:deployment])
      @options[:resume_file] = File.join(state_dir, File.basename(@options[:file]))
      if File.directory?(state_dir)
        if File.exists?(@options[:resume_file])
          unless @options[:no_resume]
            $stdout.syswrite "Resuming previous testcase...\n\n"
            # WARNING: There is an issue if you try to run a deployment through more than one feature at a time
            if File.mtime(@options[:resume_file]) < File.mtime(@options[:file])
              $stdout.syswrite "WARNING: testcase has been changed since state file.\n"
              $stdout.syswrite "Scrapping previous testcase; Starting over...\n\n"
              File.delete(@options[:resume_file])
            end
          else
            $stdout.syswrite "Scrapping previous testcase; Starting over...\n\n"
            File.delete(@options[:resume_file])
          end
        end
      else
        FileUtils.mkdir_p(state_dir)
      end
      if File.exists?(@options[:resume_file])
        $stdout.syswrite "Confirmed resuming previous testcase, using paused tests...\n\n"
        @tests_to_resume = YAML::load(IO.read(@options[:resume_file])).first["tests"]
      end
    end

    def run(*tests_to_run)
      check_for_resume
      # Create Runner, initialize VirtualMonkey::log files
      @runner = @options[:runner].new(@options[:deployment], @options)
      # Set up tests_to_run
      tests_to_run = @tests_to_resume if @tests_to_resume
      tests_to_run = @test.keys if tests_to_run.compact.empty?
      # Add the tests to the tracelog
      VirtualMonkey::trace_log.first["tests"] = tests_to_run
      @runner.write_readable_log("running tests: #{tests_to_run.join(", ")}")
      @runner.write_trace_log
      # Before
      if @options[:no_resume] and @clean_start
        @runner.transaction(:do_not_trace) { @clean_start.call }
      end
      if @before[:all]
        @runner.write_readable_log("============== BEFORE ALL ==============")
        @before[:all].call
      end
      # Test
      tests_to_run.each { |key|
        if @before[key]
          @runner.write_readable_log("============== BEFORE #{key} ==============")
          @before[key].call
        end
        if @test[key]
          @runner.write_readable_log("============== #{key} ==============")
          @test[key].call
        end
        if @after[key]
          @runner.write_readable_log("============== AFTER #{key} ==============")
          @after[key].call
        end
      }
      # After
      if @after[:all]
        @runner.write_readable_log("============== AFTER ALL ==============")
        @after[:all].call
      end
      # Successful run, delete the resume file
      FileUtils.rm_rf @options[:resume_file]
      # For being friendly to tests (multiple TestCase instances in one test)
    ensure
      VirtualMonkey::trace_log = []
    end

    def set(var, *args, &block)
      if block
        ret = yield
        (ret.is_a?(Array) ? (args += ret) : (args << ret))
      end

      case var.class.to_s
      when "Symbol"
        case var
        when :runner
          if args.first.is_a?(Class)
            @options[var] = args.first
          else
            raise "Need a VirtualMonkey::Runner Class!"
          end
        when :logs
          args.each { |log| @options[:additional_logs] << log if log.is_a?(String) }
          @options[:additional_logs].uniq!
        when :runner_options
          if args.first.is_a?(Hash)
            @options[var] ||= {}
            @options[var].deep_merge!(args.first)
          else
            raise ":runner_options can only be set to a Hash!"
          end
        when :allow_meta_monkey
          @options[var] = true
        else
          puts "#{var} is not a valid option!"
        end
      when "String"
        @options[:runner_options] ||= {}
        if args.length > 1
          @options[:runner_options][var] = args
        else
          @options[:runner_options][var] = args.first
        end
      else
        puts "#{var} is not a valid option!"
      end
    end

    def clean_start(&block)
      @clean_start = block
    end

    def before(*args, &block)
      if args.empty?
        @before[:all] = block
      else
        args.each { |test| @before[test] = block if test.is_a?(String) }
      end
    end

    def test(*args, &block)
      args.each { |test| @test[test] = block if test.is_a?(String) }
    end

    def after(*args, &block)
      if args.empty?
        @after[:all] = block
      else
        args.each { |test| @after[test] = block if test.is_a?(String) }
      end
    end

    def method_missing(sym, *args, &block)
      raise NoMethodError.new("undefined method '#{sym}' for #{inspect}:#{self.class}") unless @runner
      @runner.__send__(sym, *args, &block)
    end
  end
end
