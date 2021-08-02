require 'date'
require 'rack-flash'
require 'rack/contrib'
require 'sass'
require 'sinatra'
require 'sinatra-snap'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'slim'
require 'yaml'

%w[extensions models controllers].each do |subfolder|
  Dir.glob("./#{subfolder}/*.rb").each {|f| require_relative f}
  also_reload "./#{subfolder}/*.rb"
end

require_relative './helpers.rb'
also_reload './helpers.rb'
helpers PiggyHelpers

configure do
  $config = YAML.load(File.open('config/app.yml'))

  use Rack::JSONBodyParser
  use Rack::Session::Cookie,
        key: 'piggy.fc',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000,
        secret: $config['secret']
end
