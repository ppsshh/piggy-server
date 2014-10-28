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
    operation: '/operation/:id',
    operation_edit: '/operation/:id/edit'

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

def operation_attrs(p)
  return {
    date: Date.parse(p[:date]),
    bought_cur: p[:bought_cur].downcase,
    bought_amount: p[:bought_amount].to_f,
    sold_cur: p[:sold_cur].downcase,
    sold_amount: p[:sold_amount].to_f,
    notes: p[:notes]
  }
end

post :operations do
  o = Operation.new
  o.attributes = operation_attrs(params)
  o.save

  redirect path_to(:operations)
end

get :operation do
  o = Operation.find(params[:id])
  slim :operation, locals: {operation: o}
end

post :operation do
  o = Operation.find(params[:id])
  o.attributes = operation_attrs(params)
  o.save

  redirect path_to(:operations)
end

delete :operation do
  Operation.delete(params[:id])
  redirect path_to(:operations)
end

get :operation_edit do

end
