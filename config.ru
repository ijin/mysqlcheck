require 'rubygems'
require 'app.rb'

set :environment, ENV['RACK_ENV'].to_sym

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new('log/sinatra.log','a+')
STDOUT.reopen log
STDERR.reopen log

run Sinatra::Application

