require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'

paths index: '/'

configure do
  puts '---> init <---'

#  $config = YAML.load(File.open('config/application.yml'))

  use Rack::Session::Cookie #,
#        key: 'fcs.app',
#        domain: '172.16.0.11',
#        path: '/',
#        expire_after: 2592000,
#        secret: 'xxx'
  use Rack::Flash
end

get :index do
  slim :index
end

