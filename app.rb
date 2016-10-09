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
    graph: '/graph',
    hide_money: '/hide-money'

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/app.yml'))

  $expense_types = {}
  ExpenseType.all.each { |et| $expense_types[et.id] = et.description }
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
  $tags = {0 => {title: "NONAME"} }
  Tag.all.each { |t| $tags[t.id] = {title: t.title, parent: t.parent_id} }
  $tags.each do |k,v|
    if v[:parent] != nil
      $tags[k][:title] = $tags[v[:parent]][:title] + "/" + v[:title]
    end
  end

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
    op.title = params[:title]
    op.shop = params[:shop]
    op.expense_type = params[:expense_type]
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
  item.title = params[:title]
  item.shop = params[:shop]
  item.expense_type = params[:expense_type] ? params[:expense_type] : 0
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
  d = $config['start_date'].beginning_of_month
  @savings = {}
  while d <= Date.today
    s = BudgetRecord.where("purse = ? AND date < ?", 1, d).group(:currency).sum(:amount)
    @savings["#{d.year}-#{d.month}"] = total_in_rub(s)
    d = d.next_month
  end

  slim :savings
end
