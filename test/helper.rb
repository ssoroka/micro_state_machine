require 'simplecov'

SimpleCov.configure do
  filters.clear
  load_profile 'test_frameworks'
end

SimpleCov.start do
  add_filter "/(.rbenv|.rvm)/"
  add_filter 'vendor'
end
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts "#{e.message}\nRun `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/autorun'
require 'minitest/spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'micro_state_machine'

Minitest.autorun
