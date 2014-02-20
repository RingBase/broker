require File.expand_path(File.dirname(__FILE__) + '/lib/broker')

task :broker do
  Broker.run!
end

task :simulator do
  require 'irb'
  require 'irb/completion'
  require File.expand_path(File.dirname(__FILE__) + '/lib/broker')
  require File.expand_path(File.dirname(__FILE__) + '/lib/simulator')
  ARGV.clear
  IRB.start
end
