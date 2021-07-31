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
  $purse = {0 => 'Normal', 1 => 'Savings', 2 => 'Anchors (not included in monthly diffs)', 3 => 'Monthly diffs (not included in anchors)'}
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
  use Rack::JSONBodyParser
end
