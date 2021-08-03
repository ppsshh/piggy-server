require 'rack/contrib'
require 'sinatra'
require 'sinatra-snap'
require 'sinatra/activerecord'
require 'yaml'
require 'sinatra/reloader'

%w[extensions models controllers].each do |subfolder|
  Dir.glob("./#{subfolder}/*.rb").each {|f| require_relative f}
  also_reload "./#{subfolder}/*.rb"
end

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

def protect!
  return if session['username'].present?

  halt 401, "Unauthorized"
end
