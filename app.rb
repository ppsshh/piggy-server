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
require_relative './price.rb'

also_reload './helpers.rb'
also_reload './budget.rb'
also_reload './models.rb'
also_reload './price.rb'

paths index: '/',
    budget: '/budget',
    budget_record: '/budget/record/:id',
    budget_year_month: '/budget/month/:year/:month',
    savings: '/savings',
    summary: '/summary/:year',
    tag_summary: '/summary/:year/:tag_id',
    global_tag_summary: '/summary2/:year/:tag_id',
    exrates: '/exrates',
    exrate: '/exrate/:id',
    graph: '/graph',
    hide_money: '/hide-money',
    autocomplete_shop: '/autocomplete/shop',
    mortgage: '/mortgage',
    prices_reload: '/prices_reload'

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/app.yml'))

  $purse = {0 => "Normal", 1 => "Savings"}
  $main_currency = Currency.where(title: "RUB").take
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
  @savings = income_expense_total( BudgetRecord.where("purse = ? AND date < ?", 1, Date.new(y, m, 1)) )
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

    op.income_amount = params[:income_amount]
    op.income_currency_id = params[:income_currency_id]
    op.expense_amount = params[:expense_amount]
    op.expense_currency_id = params[:expense_currency_id]

    op.is_conversion = params[:is_conversion] ? true : false
    op.description = params[:description]
    op.shop = params[:shop]
    op.tag_id = params[:tag_id].to_i
    op.purse = params[:purse].to_i
    op.save

    flash[:notice] = "Record successfully created"
  rescue StandardError
    flash[:error] ||= "Unable to create new record: #{params[:date]}, #{params[:income_amount]}, #{params[:expense_amount]} #{params[:description]} @ #{params[:shop]}, #{params[:operation_type]}"
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

  item.income_amount = params[:income_amount]
  item.income_currency_id = params[:income_currency_id]
  item.expense_amount = params[:expense_amount]
  item.expense_currency_id = params[:expense_currency_id]

  item.is_conversion = params[:is_conversion] ? true : false
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
  update_anchors
  @anchors = Anchor.all.order(date: :asc)

  slim :savings
end

get :summary do
  @year = params[:year].to_i || Date.today.year
  expenses_by_tag = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0).where('expense_amount > 0').group(:tag_id).sum(:expense_amount)

  expenses = {}
  expenses_sub = {}
  @tags = tags
  expenses_by_tag.each do |k,v|
    tag_parent = @tags[k][:parent] || k

    expenses[tag_parent] = (expenses[tag_parent] || 0) + v

    expenses_sub[tag_parent] ||= {}
    expenses_sub[tag_parent][k] = v
  end

  @expenses_sub = {}
  expenses_sub.each do |k,v|
    @expenses_sub[k] = expenses_sub[k].sort_by { |k,v| v }.to_h
  end

  @expenses = expenses.sort_by { |k,v| v }.reverse.to_h

  slim :summary
end

get :tag_summary do
  @year = params[:year].to_i || Date.today.year
  @tag = params[:tag_id].to_i

  @expenses = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0,
        tag_id: @tag).where(
        'expense_amount > 0').order(
        expense_amount: :desc)

  slim :tag_summary
end

get :global_tag_summary do
  @year = params[:year].to_i || Date.today.year
  @tag = params[:tag_id].to_i
  tags = [@tag]
  Tag.where(parent_id: @tag).map {|t| tags << t.id}

  @expenses = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0,
        tag_id: tags).where(
        'expense_amount > 0').order(
        expense_amount: :desc)

  slim :tag_summary
end

get :autocomplete_shop do
  term2 = params[:term].downcase.tr("qwertyuiop[]asdfghjkl;'zxcvbnm,.`", "йцукенгшщзхъфывапролджэячсмитьбюё")
  items = BudgetRecord.select(:shop).where('"shop" ILIKE ? OR "shop" ILIKE ?', "%#{params[:term]}%", "%#{term2}%").group(:shop).limit(10)
  items_array = []
  items.each { |i| items_array << i.shop }

  content_type :json
  items_array.to_json
end

get :mortgage do
  slim :mortgage
end

get :exrates do
  redirect path_to(:exrate).with($main_currency.id)
end

get :exrate do
  @currency = Currency.find(params[:id])
  @prices = @currency.prices.order(actual_date: :desc)
  slim :exrate
end

get :prices_reload do
  $price_converter.reload
  redirect path_to(:index)
end
