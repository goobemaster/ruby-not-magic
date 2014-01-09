require 'childprocess'

class SeleniumServer

  attr_accessor :jar
  attr_accessor :role
  attr_accessor :process
  attr_accessor :log
  attr_accessor :log_filename

  def initialize(role)
    jar = File.dirname(__FILE__) + '/../drivers/selenium/selenium-server-standalone-2.39.0.jar'
    raise Errno::ENOENT, jar unless File.exist?(jar)
    raise 'Selenium Server accepts only hub or node roles!' if role != 'hub' && role != 'node'
    @jar = jar
    @log_filename = "selenium-#{Time.now.to_i}.log"
    @role = role
    @log = File.open(@log_filename, "w")
    @process = nil
  end

  def start
    puts("Starting Selenium Server...")
    process.start

    # Wait until Selenium Server fully starts
    until is_started()
      # Do nothing, just wait. Todo: Implement a timeout!
      if is_exiting()
        stop
        raise "Something went wrong during startup of Selenium Server #{@role}... Please check logfile: #{@log_filename}"
      end
    end
    puts "#{@role} started!\n\n"
  end

  def stop
    puts "Stopping..."
    stop_process if @process
    @log.close if @log
  end

  def stop_process
    return unless @process.alive?

    begin
      @process.poll_for_exit(5)
    rescue ChildProcess::TimeoutError
      @process.stop
    end
  rescue Errno::ECHILD
    # already dead
  ensure
    @process = nil
  end

  def process
    @process ||= (
    if @role == 'hub'
      cp = ChildProcess.new("java", "-jar", @jar, '-role', 'hub')
    else
      cp = ChildProcess.new("java", "-jar", @jar, '-role', 'node', '-hub', 'http://localhost:4444/grid/register')
    end
    cp.detach = true # Start in the background
    cp.io.stdout = cp.io.stderr = @log
    cp
    )
  end

  def is_started
    if @role == 'hub'
      File.read(@log_filename).each_line { |line |
        return true if line.include?('AbstractConnector:Started')
      }
    else
      sleep 5
      return true unless is_exiting()
    end
    false
  end

  def is_exiting
    File.read(@log_filename).each_line { |line |
      if @role == 'hub'
        true if line =~ /Exception in thread|Address already in use/
      else
        true if line =~ /\.exception|Hub is down or not responding/
      end
    }
    false
  end
end