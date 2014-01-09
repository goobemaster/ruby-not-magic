require Dir.getwd() + '/common/grid.rb'

raise 'Please provide your browsers!' if ARGV[0].nil?
$browsers = ARGV[0].split(',')
raise 'No browsers specified!' if $browsers.size == 0

$selenium_hub = SeleniumServer.new('hub')
$selenium_hub.start
$selenium_nodes = []
$threads = $browsers.size
$feature_file = ARGV[1]
$feature_tag = ARGV[2]
tasklist = []

def bye(message, code)
  code = 0 if code < 0 || code > 100
  puts message
  exit code
end

$threads.times {
  node = SeleniumServer.new('node')
  node.start
  $selenium_nodes << node
}

(1..$threads.to_i).each { |task_id|
  task = Thread.new(task_id) {
    log = File.new("results/cucumber_output_#{task_id}.log", "w")
    cmd = "set browser=#{$browsers[task_id - 1]}_grid&set domain=co.uk&bundle exec cucumber \"#{$feature_file}\" --tags #{$feature_tag} --format html --out results/cucumber_results_#{$browsers[task_id - 1]}.html"
    output = `#{cmd}`
    log.write(output)
    log.close
  }
  tasklist << task
}

tasklist.each { |task|
  task.join
}

failed = 0

(1..tasklist.length).each { |task_id|
  log = File.read("results/cucumber_output_#{task_id}.log")
  failed += 1 if log.include?("Failing Scenarios:")
}

$selenium_hub.stop

$selenium_nodes.each { |node|
  node.stop
}

if failed > 0
  bye("Failure! #{failed} threads reported failing scenarios!", failed)
else
  bye("Success", 0)
end