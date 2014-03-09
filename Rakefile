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
    Thread.new { EM.run }
    IRB.start
  end

  task :listen do
    th = Thread.new { EM.run }
    Invoca.listen
    th.join
  end
end
