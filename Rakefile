require File.expand_path(File.dirname(__FILE__) + '/lib/broker')

namespace :broker do
  task :start do
    Broker.run!
  end

  task :console do
    require 'irb'
    require 'irb/completion'
    require File.expand_path(File.dirname(__FILE__) + '/lib/broker')
    require File.expand_path(File.dirname(__FILE__) + '/lib/simulator')
    ARGV.clear
    IRB.start
  end
end
