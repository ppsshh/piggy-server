require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/activerecord'
require 'sinatra-snap'
require 'slim'

require 'rack-flash'
require 'yaml'
require 'date'

require_relative './models/all.rb'

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
    budget_expense: '/budget/expense/:id',
    budget_income: '/budget/income/:id',
    budget_req_expense: '/budget/req_expense/:id'

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

helpers do
  def currency_symbol(currency)
    currency = currency.to_s.downcase.to_sym
    currency_symbols = {
      usd: '$',
      eur: '€',
      jpy: '¥',
      rub: '₽'
    }

    return currency_symbols[currency.downcase] || currency.upcase
  end

  def money_format(amount, currency)
    parts = amount.round(2).to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1 ")
    parts.delete_at(1) if parts[1] == "0"

    return "#{parts.join('.')} #{currency_symbol(currency)}"
  end
end

class CurObj # currency object
  attr_reader :total, :parts
  def total
    @total
  end

  def parts
    clean!
    @parts
  end

  def initialize
    @parts = {}
    @total = 0
  end

  def inspect
    clean!
    {parts: @parts, total: @total}
  end

  def exchange(amount, spend_cur, spend_amount)
    spend_cur = cursym(spend_cur)

    @parts[spend_cur] ||= {to: 0, from: 0}
    @parts[spend_cur][:to] += amount
    @parts[spend_cur][:from] += spend_amount

    @total += amount
  end

  def subtract(amount)
    @parts.each do |k,v|
      percent = v[:to] / @total
      sub = amount * percent
      part = (v[:to] - sub) / v[:to]

      v[:to] -= sub
      v[:from] *= part
    end
    @total -= amount
  end

  def append(amount)
    @parts.each do |k,v|
      percent = v[:to] / @total
      v[:to] += amount * percent
    end

    @total += amount
  end

  def charge(cur, amount)
    cur = cursym(cur)

    @parts[cur] ||= {to: 0, from: 0}
    @parts[cur][:from] += amount
  end

  def clean!
    @parts.each do |k,v|
      @parts.delete(k) if v[:to] == 0 && v[:from] == 0
    end
  end
end

def get_operations_sorted()
  operations = []

  SavingsExchange.all.each { |i| operations << i }
  SavingsProfit.all.each   { |i| operations << i }
  SavingsAccountCharge.all.each { |i| operations << i }
  SavingsExpense.all.each  { |i| operations << i }

  return operations
end

def cursym(cur)
  cur.to_s unless cur.kind_of?(String)
  return cur.downcase.to_sym
end

def get_overall()
  operations = get_operations_sorted

  cur_hash = {}
  operations.sort.each do |o|
    if o.kind_of?(SavingsExchange)
      c= cursym(o.bought_cur)
      cur_hash[c] ||= CurObj.new
      cur_hash[c].exchange(o.bought_amount, o.sold_cur, o.sold_amount)

      if o.is_income == false
        cur_hash[cursym(o.sold_cur)].subtract(o.sold_amount)
      end

    elsif o.kind_of?(SavingsProfit)
      c = cursym(o.cur)
      cur_hash[c] ||= CurObj.new
      cur_hash[c].append(o.amount)

    elsif o.kind_of?(SavingsAccountCharge)
      c = cursym(o.target_cur)
      cur_hash[c] ||= CurObj.new
      if c == cursym(o.charge_cur)
        cur_hash[c].append(o.charge_amount * -1)
      else
        cur_hash[c].charge(o.charge_cur, o.charge_amount)
      end

    elsif o.kind_of?(SavingsExpense)
      c = cursym(o.cur)
      cur_hash[c] ||= CurObj.new
      cur_hash[c].subtract(o.amount)
    end
  end

  @result = cur_hash
end

def convert_currency(rates, amount, cur1, cur2)
  cur1 = cur1.to_s.downcase
  cur2 = cur2.to_s.downcase

  if cur1 == 'usd'
    return amount if cur2 == 'usd'
    return amount / rates[cur2]
  elsif cur2 == 'usd'
    return rates[cur1] * amount
  else
    return rates[cur1] * amount / rates[cur2]
  end
end


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

def get_days_range(d)
  dnext = d
  while dnext.day != $config['budget_start_day'] do dnext += 1 end
  dprev = d
  while dprev.day != $config['budget_start_day'] do dprev -= 1 end

  return [dprev, dnext]
end

def get_date_hash(items_array, date_key)
  h = {}
  items_array.each do |i|
    h[i[date_key]] ||= []
    h[i[date_key]] << i
  end
  return h
end

def get_budget_data
  # d1 -- d2 -- today -- d3 -- d4
  d1, d2 = get_days_range(Date.today.prev_month)
  d3, d4 = get_days_range(Date.today.next_month)

  @drange = [d1, d2, d3, d4]
  # eg. incomes:  11 jan .. 10 feb
  # eg. expenses: 10 feb ..  9 mar
  @incomes = BudgetIncome.where(date: (d1+1)..d2 ).order(date: :asc)
  @expenses = get_date_hash(BudgetExpense.where(date: d2..(d3-1) ).order(date: :asc), :date)
  @req_expenses = BudgetRequiredExpense.where(date: d2..(d3-1) ).order(date: :asc)

  @next_incomes = BudgetIncome.where(date: (d2+1)..d3 ).order(date: :asc)
  @next_expenses = {} # always empty
  @next_req_expenses = BudgetRequiredExpense.where(date: d3..(d4-1) ).order(date: :asc)
end

get :index do
  get_budget_data
  slim :budget
end

get :budget do
  get_budget_data
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
  update_budget_item(BudgetExpense.find(params[:id]))
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
