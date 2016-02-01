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
    operations: '/operations/', # list of all operations
    graph: '/graph',
    exchanges: '/exchanges', # post (new)
    exchange: '/exchange/:id', # edit page, modify, delete
    profits: '/profits', # post(new)
    profit: '/profit/:id', # edit page, modify
    account_charges: '/account_charges', # post(new)
    account_charge: '/account_charge/:id', # edit page, modify
    expenses: '/expenses', # post(new)
    expense: '/expense/:id', # edit page, modify
    budget: '/budget'

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

  Exchange.all.each { |i| operations << i }
  Profit.all.each   { |i| operations << i }
  AccountCharge.all.each { |i| operations << i }
  Expense.all.each  { |i| operations << i }

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
    if o.kind_of?(Exchange)
      c= cursym(o.bought_cur)
      cur_hash[c] ||= CurObj.new
      cur_hash[c].exchange(o.bought_amount, o.sold_cur, o.sold_amount)

      if o.is_income == false
        cur_hash[cursym(o.sold_cur)].subtract(o.sold_amount)
      end

    elsif o.kind_of?(Profit)
      c = cursym(o.cur)
      cur_hash[c] ||= CurObj.new
      cur_hash[c].append(o.amount)

    elsif o.kind_of?(AccountCharge)
      c = cursym(o.target_cur)
      cur_hash[c] ||= CurObj.new
      if c == cursym(o.charge_cur)
        cur_hash[c].append(o.charge_amount * -1)
      else
        cur_hash[c].charge(o.charge_cur, o.charge_amount)
      end

    elsif o.kind_of?(Expense)
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


get :index do
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

  slim :index
end

def get_days_range(d)
  dnext = d
  while dnext.day != $config['budget_start_day'] do dnext += 1 end
  dprev = d
  while dprev.day != $config['budget_start_day'] do dprev -= 1 end

  return [dprev, dnext]
end

get :budget do
  dprev, dnext = get_days_range(Date.today)
  @coming_incomes = BudgetIncome.where(date: dprev..(dnext-1) ).order(date: :asc)
  @coming_incomes_range = [dprev, dnext]

  dprev, dnext = get_days_range(Date.today.prev_month)
  @current_incomes = BudgetIncome.where(date: dprev..(dnext-1) ).order(date: :asc)
  @current_incomes_range = [dprev, dnext]

  slim :budget
end

post :budget do
  begin
    begin
      date = Date.parse(params[:date])
    rescue StandardError, ArgumentError
      flash[:error] = "Invalid date: #{params[:date]}"
      redirect path_to(:budget)
    end

    if params[:operation_type] == "expense"
      op = BudgetExpense.new(date: date,
            amount: params[:amount].to_f,
            description: params[:description])
      op.save
    elsif params[:operation_type] == "income"
      op = BudgetIncome.new(date: date,
            amount: params[:amount].to_f,
            description: params[:description])
      op.save
    else
      flash[:error] = "Invalid operation_type: #{params[:operation_type]}"
      redirect path_to(:budget)
    end

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
  @operations = Exchange.all

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

post :exchanges do
  o = Exchange.new
  o.attributes = exchange_attrs(params)
  o.save

  redirect path_to(:index)
end

get :exchange do
  o = Exchange.find(params[:id])
  slim :exchange, locals: {exchange: o}
end

post :exchange do
  o = Exchange.find(params[:id])
  o.attributes = exchange_attrs(params)
  o.save

  redirect path_to(:index)
end

delete :exchange do
  Exchange.delete(params[:id])
  redirect path_to(:index)
end

def profit_attrs(p)
  return {
    date: p['date'],
    amount: p['amount'],
    cur: p['cur'],
    notes: p['notes']
  }
end

post :profits do
  o = Profit.new
  o.attributes = profit_attrs(params)
  o.save

  redirect path_to(:index)
end

get :profit do
  o = Profit.find(params[:id])
  slim :profit, locals: {profit: o}
end

post :profit do
  o = Profit.find(params[:id])
  o.attributes = profit_attrs(params)
  o.save

  redirect path_to(:index)
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

post :account_charges do
  o = AccountCharge.new
  o.attributes = account_charge_attrs(params)
  o.save

  redirect path_to(:index)
end

get :account_charge do
  o = AccountCharge.find(params[:id])
  slim :account_charge, locals: {acch: o}
end

post :account_charge do
  o = AccountCharge.find(params[:id])
  o.attributes = account_charge_attrs(params)
  o.save

  redirect path_to(:index)
end

def expense_attrs(p)
  return {
    date: p['date'],
    amount: p['amount'],
    cur: p['cur'],
    notes: p['notes']
  }
end

post :expenses do
  o = Expense.new
  o.attributes = expense_attrs(params)
  o.save

  redirect path_to(:index)
end

get :expense do
  o = Expense.find(params[:id])
  slim :expense, locals: {expense: o}
end

post :expense do
  o = Expense.find(params[:id])
  o.attributes = expense_attrs(params)
  o.save

  redirect path_to(:index)
end

