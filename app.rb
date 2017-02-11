require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'date'

require_relative './helpers.rb'
require_relative './models.rb'
require_relative './budget.rb'

also_reload './helpers.rb'
also_reload './budget.rb'
also_reload './models.rb'

paths index: '/',
    budget: '/budget',
    budget_record: '/budget/record/:id',
    budget_year_month: '/budget/month/:year/:month',
    savings: '/savings',
    summary: '/summary/:year',
    graph: '/graph',
    hide_money: '/hide-money',
    autocomplete_shop: '/autocomplete/shop'

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/app.yml'))

  $purse = {0 => "Normal", 1 => "Savings"}

  use Rack::Session::Cookie,
        key: 'piggy.fc',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000,
        secret: $config['secret']
  use Rack::Flash
end

helpers PiggyHelpers

get :index do
  redirect path_to(:budget_year_month).with(Date.today.year, Date.today.month)
end

get :budget do
  redirect path_to(:budget_year_month).with(Date.today.year, Date.today.month)
end

get :budget_year_month do
  $tags = tags
  y, m = params[:year].to_i, params[:month].to_i
  get_budget_data(y, m)
  @budget_date = Date.new(y, m)
  @savings = BudgetRecord.where("purse = ? AND date < ?", 1, Date.new(y, m, 1)).group(:currency).sum(:amount)
  slim :budget
end

post :budget do
  begin
    begin
      date = Date.parse(params[:date])
    rescue StandardError, ArgumentError
      flash[:error] = "Invalid date: #{params[:date]}"
      throw StandardError.new
    end

    op = BudgetRecord.new
    op.date = date
    op.amount = params[:amount].to_f
    op.currency = params[:currency].downcase
    op.description = params[:description]
    op.shop = params[:shop]
    op.tag_id = params[:tag_id].to_i
    op.purse = params[:purse].to_i
    op.save

    flash[:notice] = "Record successfully created"
  rescue StandardError
    flash[:error] ||= "Unable to create new record: #{params[:date]}, #{params[:amount]}, #{params[:description]} @ #{params[:shop]}, #{params[:operation_type]}"
  end

  redirect path_to(:budget_year_month).with(op.date.year, op.date.month)
end

get :graph do
  @operations = SavingsExchange.all

  slim :graph
end

get :budget_record do
  @item = BudgetRecord.find(params[:id])
  slim :budget_item
end

post :budget_record do
  item = BudgetRecord.find(params[:id])

  item.date = params[:date]
  item.amount = params[:amount].to_f
  item.currency = params[:currency].downcase
  item.description = params[:description]
  item.shop = params[:shop]
  item.tag_id = params[:tag_id].to_i
  item.purse = params[:purse].to_i
  item.save

  redirect path_to(:budget_year_month).with(item.date.year, item.date.month)
end

delete :budget_record do
  item = BudgetRecord.find(params[:id])
  y, m = item.date.year, item.date.month

  item.destroy

  redirect path_to(:budget_year_month).with(y, m)
end

post :hide_money do
  if params["hide-money"] && params["hide-money"] == "true"
    request.session["hide-money"] = true
    return 200, '{"hide-money": true}'
  else
    request.session["hide-money"] = false
    return 200, '{"hide-money": false}'
  end
end

get :savings do
  d = $config['savings_start_date'].beginning_of_month
  @savings = {}
  while d <= Date.today
    s = BudgetRecord.where("purse = ? AND date < ?", 1, d).group(:currency).sum(:amount)
    @savings["#{d.year}-#{d.month}"] = total_in_rub(s, Date.new(d.year, d.month, 1))
    d = d.next_month
  end

  slim :savings
end

get :summary do
  year = params[:year].to_i || 2016
  expenses_by_tag = BudgetRecord.where(date: (Date.new(year, 1, 1)..Date.new(year, 12, 31)), purse: 0).where('amount < 0').group(:tag_id).sum(:amount)

  expenses = {}
  expenses_sub = {}
  @tags = tags
  expenses_by_tag.each do |k,v|
    tag_parent = @tags[k][:parent] || k

    expenses[tag_parent] ||= 0
    expenses[tag_parent] += v

    expenses_sub[tag_parent] ||= {}
    expenses_sub[tag_parent][k] = v
  end

  @expenses_sub = {}
  expenses_sub.each do |k,v|
    @expenses_sub[k] = expenses_sub[k].sort_by { |k,v| v }.to_h
  end

  @expenses = expenses.sort_by { |k,v| v }.to_h

  slim :summary
end

get :autocomplete_shop do
  term2 = params[:term].downcase.tr("qwertyuiop[]asdfghjkl;'zxcvbnm,.`", "йцукенгшщзхъфывапролджэячсмитьбюё")
  items = BudgetRecord.select(:shop).where('"shop" ILIKE ? OR "shop" ILIKE ?', "%#{params[:term]}%", "%#{term2}%").group(:shop).limit(10)
  items_array = []
  items.each { |i| items_array << i.shop }

  content_type :json
  items_array.to_json
end
