require File.expand_path(File.dirname(__FILE__) + '/lib/broker')
require 'eventmachine'
require File.expand_path(File.dirname(__FILE__) + '/lib/simulator')

task :broker do
  Broker.run!
end

namespace :simulator do
  task :start do
    require 'irb'
    require 'irb/completion'
    ARGV.clear
    IRB.start
  end

  task :listen do
    EM.run do
      Invoca.listen
    end
  end
end
