require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'date'

require_relative './models/currency.rb'
require_relative './models/operation.rb'

paths index: '/',
    operations: '/operations',
    operations_new: '/operations/new',
    operation_edit: '/operation/:id'

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/app.yml'))

  use Rack::Session::Cookie,
        key: 'piggy.fc',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000,
        secret: $config['secret']
  use Rack::Flash
end

get :index do
  slim :index
end

get :operations do
  @operations = Operation.all
  slim :operations
end

post :operations do
  o = Operation.new
puts params.inspect
  o.date = Date.parse(params[:date])

  o.bought_cur = params[:bought_cur].downcase
  o.bought_amount = params[:bought_amount].to_i

  o.sold_cur = params[:sold_cur].downcase
  o.sold_amount = params[:sold_amount].to_i

  o.notes = params[:notes]
  o.save

  redirect path_to(:operations)
end

get :operations_new do

end

get :operation_edit do

end
