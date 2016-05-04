require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'date'

require_relative './helpers.rb'
require_relative './models/all.rb'
require_relative './savings.rb'
require_relative './budget.rb'

paths index: '/',
    savings: '/savings',
    operations: '/operations/', # list of all operations
    graph: '/graph',
    savings_exchanges: '/savings/exchanges', # post (new)
    savings_exchange: '/savings/exchange/:id', # edit page, modify, delete
    savings_profits: '/savings/profits', # post(new)
    savings_profit: '/savings/profit/:id', # edit page, modify
    savings_account_charges: '/savings/account_charges', # post(new)
    savings_account_charge: '/savings/account_charge/:id', # edit page, modify
    savings_expenses: '/savings/expenses', # post(new)
    savings_expense: '/savings/expense/:id', # edit page, modify
    budget: '/budget',
    budget_month: '/budget/month/:id',
    budget_expense: '/budget/expense/:id',
    budget_income: '/budget/income/:id',
    budget_req_expense: '/budget/req_expense/:id'

configure do
  puts '---> init <---'

  $config = YAML.load(File.open('config/app.yml'))

  $expense_types = {
    0 => {name: "default", description: "Не выбрано"},
    1 => {name: "food", description: "Еда (и хозтовары)"},
    2 => {name: "car", description: "Машина"},
    3 => {name: "beauty", description: "Одежда и имидж"},
    4 => {name: "transport", description: "Общественный транспорт"}
  }

  use Rack::Session::Cookie,
        key: 'piggy.fc',
#        domain: '172.16.0.11',
#        path: '/',
        expire_after: 2592000,
        secret: $config['secret']
  use Rack::Flash
end

helpers PiggyHelpers

get :savings do
  get_overall()

  @rates = {}
  $config["currencies"].each do |c|
    @rates[c] ||= Currency.closest(c, Date.today).rate
  end

  @total_rub = 0
  ['usd', $config['currencies']].flatten.each do |c|
    c = c.to_sym
    amount = @result[c] ? @result[c].total : 0
    @total_rub += convert_currency(@rates, amount, c, 'rub')
  end

  slim :savings
end

get :index do
  get_budget_data
  slim :budget
end

get :budget do
  get_budget_data
  slim :budget
end

get :budget_month do
  d = Date.today
  params[:id].to_i.times do |i|
    d = d.prev_month
  end

  get_budget_data(d)
  slim :budget_month, locals: {
    incomes: @incomes,
    expenses: @expenses,
    req_expenses: @req_expenses,
    date_start: @drange[1],
    date_end: @drange[2]
  }
end

post :budget do
  begin
    begin
      date = Date.parse(params[:date])
    rescue StandardError, ArgumentError
      flash[:error] = "Invalid date: #{params[:date]}"
      throw StandardError.new
    end

    if params[:operation_type] == "expense"
      op = BudgetExpense.new
    elsif params[:operation_type] == "income"
      op = BudgetIncome.new
    elsif params[:operation_type] == "required_expense"
      op = BudgetRequiredExpense.new
    else
      flash[:error] = "Invalid operation_type: #{params[:operation_type]}"
      throw StandardError.new
    end
    op.date = date
    op.amount = params[:amount].to_f
    op.description = params[:description]
    op.save

    flash[:notice] = "Record successfully created"
  rescue StandardError
    flash[:error] ||= "Unable to create new record: #{params[:date]}, #{params[:amount]}, #{params[:description]}, #{params[:operation_type]}"
  end

  redirect path_to(:budget)
end

get :operations do
  @operations = get_operations_sorted

  slim :operations
end

get :graph do
  @operations = SavingsExchange.all

  slim :graph
end

def exchange_attrs(p)
  return {
    date: DateTime.parse(p[:date]),
    is_income: p.has_key?("is_income"),
    bought_cur: p[:bought_cur].downcase,
    bought_amount: p[:bought_amount].to_f,
    sold_cur: p[:sold_cur].downcase,
    sold_amount: p[:sold_amount].to_f,
    notes: p[:notes]
  }
end

post :savings_exchanges do
  o = SavingsExchange.new
  o.attributes = exchange_attrs(params)
  o.save

  redirect path_to(:savings)
end

get :savings_exchange do
  o = SavingsExchange.find(params[:id])
  slim :savings_exchange, locals: {exchange: o}
end

post :savings_exchange do
  o = SavingsExchange.find(params[:id])
  o.attributes = exchange_attrs(params)
  o.save

  redirect path_to(:savings)
end

delete :savings_exchange do
  SavingsExchange.delete(params[:id])
  redirect path_to(:savings)
end

def profit_attrs(p)
  return {
    date: p['date'],
    amount: p['amount'],
    cur: p['cur'],
    notes: p['notes']
  }
end

post :savings_profits do
  o = SavingsProfit.new
  o.attributes = profit_attrs(params)
  o.save

  redirect path_to(:savings)
end

get :savings_profit do
  o = SavingsProfit.find(params[:id])
  slim :savings_profit, locals: {profit: o}
end

post :savings_profit do
  o = SavingsProfit.find(params[:id])
  o.attributes = profit_attrs(params)
  o.save

  redirect path_to(:savings)
end

def account_charge_attrs(p)
  return {
    date: p['date'],
    charge_amount: p['charge_amount'],
    charge_cur: p['charge_cur'],
    target_cur: p['target_cur'],
    is_income: p.has_key?("is_income"),
    notes: p['notes']
  }
end

post :savings_account_charges do
  o = SavingsAccountCharge.new
  o.attributes = account_charge_attrs(params)
  o.save

  redirect path_to(:savings)
end

get :savings_account_charge do
  o = SavingsAccountCharge.find(params[:id])
  slim :savings_account_charge, locals: {acch: o}
end

post :savings_account_charge do
  o = SavingsAccountCharge.find(params[:id])
  o.attributes = account_charge_attrs(params)
  o.save

  redirect path_to(:savings)
end

def expense_attrs(p)
  return {
    date: p['date'],
    amount: p['amount'],
    cur: p['cur'],
    notes: p['notes']
  }
end

post :savings_expenses do
  o = SavingsExpense.new
  o.attributes = expense_attrs(params)
  o.save

  redirect path_to(:savings)
end

get :savings_expense do
  o = SavingsExpense.find(params[:id])
  slim :savings_expense, locals: {expense: o}
end

post :savings_expense do
  o = SavingsExpense.find(params[:id])
  o.attributes = expense_attrs(params)
  o.save

  redirect path_to(:savings)
end

get :budget_expense do
  @item = BudgetExpense.find(params[:id])
  slim :budget_item, locals: {operation_type: :budget_expense}
end

get :budget_income do
  @item = BudgetIncome.find(params[:id])
  slim :budget_item, locals: {operation_type: :budget_income}
end

get :budget_req_expense do
  @item = BudgetRequiredExpense.find(params[:id])
  slim :budget_item, locals: {operation_type: :budget_req_expense}
end

def update_budget_item(i)
  i.date = params[:date]
  i.amount = params[:amount]
  i.description = params[:description]
  i.save
end

post :budget_expense do
  item = BudgetExpense.find(params[:id])
  update_budget_item(item)
  item.expense_type = params[:expense_type]
  item.save
  redirect path_to(:budget)
end

post :budget_income do
  update_budget_item(BudgetIncome.find(params[:id]))
  redirect path_to(:budget)
end

post :budget_req_expense do
  update_budget_item(BudgetRequiredExpense.find(params[:id]))
  redirect path_to(:budget)
end
