require 'date'
require 'rack-flash'
require 'sass'
require 'sinatra'
require 'sinatra-snap'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'slim'
require 'yaml'

Dir.glob('./models/*.rb').each {|f| require_relative f}
Dir.glob('./controllers/*.rb').each {|f| require_relative f}
also_reload './models/*.rb'
also_reload './controllers/*.rb'

require_relative './helpers.rb'
also_reload './helpers.rb'
helpers PiggyHelpers

configure do
  $config = YAML.load(File.open('config/app.yml'))
  $purse = {0 => "Normal", 1 => "Savings"}
  $main_currency = Currency.where(title: "JPY").take
  $currencies = {}
  Currency.all.each { |c| $currencies[c.id] = c }
  $price_converter = PriceConverter.new

  use Rack::Session::Cookie,
        key: 'piggy.fc',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000,
        secret: $config['secret']
  use Rack::Flash
end
