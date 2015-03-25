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
    expense: '/expense/:id' # edit page, modify

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
    currency_symbols = {
      'usd' => '$',
      'eur' => '€',
      'jpy' => '¥',
      'rub' => '₽'
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

class Vpc
  def create_hash(cur1, cur2)
    @e ||= {}
    @e[cur1] ||= {}
    @e[cur1][cur2] ||= {}
    @e[cur1][cur2]['vol'] ||= 0
    @e[cur1][cur2]['amount'] ||= 0
  end

  def clean_hash
    @e.keys.each do |k1|
      @e[k1].keys.each do |k2|
        @e[k1].delete(k2) if @e[k1][k2]['vol'] == 0 && @e[k1][k2]['amount'] == 0
      end
      @e.delete(k1) if @e[k1].empty?
    end
  end

  def add_income(income_cur, income_amount, target_cur, target_amount)
    income_cur = income_cur.downcase
    target_cur = target_cur.downcase

    create_hash(target_cur, income_cur)

    @e[target_cur][income_cur]['vol'] += target_amount
    @e[target_cur][income_cur]['amount'] += income_amount
  end

  def add_profit(income_cur, income_amount)
    income_cur = income_cur.downcase

    raise StandardError.new("There is no #{income_cur} in your savings") unless @e.has_key?(income_cur)

    vol = 0
    @e[income_cur].each { |k,v| vol += v['vol'] }
    @e[income_cur].each do |k,v|
      part = income_amount/vol.to_f
      v['vol'] += part * v['vol']
    end
  end

  def charge_from_income(charge_cur, charge_amount, target_cur)
    charge_cur = charge_cur.downcase
    target_cur = target_cur.downcase

    @e[target_cur][charge_cur]['amount'] += charge_amount
  end

  def exchange(sold_cur, sold_amount, bought_cur, bought_amount)
    sold_cur = sold_cur.downcase
    bought_cur = bought_cur.downcase

    raise StandardError.new("There is no #{sold_cur} in your savings") unless @e.has_key?(sold_cur)
    create_hash(bought_cur, sold_cur)

    vol = 0
    @e[sold_cur].each { |k,v| vol += v['vol'] }
    @e[sold_cur].each do |k,v|
      part = v['vol']/vol.to_f
      amount = part * v['amount']
      v['vol'] -= sold_amount * part
      v['amount'] -= amount

      @e[bought_cur][k] ||= {}
      @e[bought_cur][k]['vol'] ||= 0
      @e[bought_cur][k]['vol'] += bought_amount * part
      @e[bought_cur][k]['amount'] ||= 0
      @e[bought_cur][k]['amount'] += amount
    end
  end

  def get_hash
    return @e
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

def get_overall()
  operations = get_operations_sorted

  income = {}
  total = {}
  vpc = Vpc.new # VPC = value per currency

  operations.sort.each do |o|
    if o.kind_of?(Exchange)
      bought_cur = o.bought_cur.downcase
      sold_cur = o.sold_cur.downcase

      if o.is_income
        income[sold_cur] ||= 0
        income[sold_cur] += o.sold_amount

        vpc.add_income(sold_cur, o.sold_amount, bought_cur, o.bought_amount)
      else
        total[sold_cur] ||= 0
        total[sold_cur] -= o.sold_amount

        vpc.exchange(sold_cur, o.sold_amount, bought_cur, o.bought_amount)
      end

      total[bought_cur] ||= 0
      total[bought_cur] += o.bought_amount

    elsif o.kind_of?(Profit)
      cur = o.cur.downcase

      total[cur] ||= 0
      total[cur] += o.amount

      vpc.add_profit(cur, o.amount)

    elsif o.kind_of?(AccountCharge)
      target_cur = o.target_cur.downcase
      charge_cur = o.charge_cur.downcase

      if o.is_income
        income[charge_cur] ||= 0
        income[charge_cur] -= o.charge_amount

        vpc.charge_from_income(charge_cur, o.charge_amount, target_cur)
      elsif target_cur == charge_cur
        total[charge_cur] ||= 0
        total[charge_cur] -= o.charge_amount

        vpc.add_profit(charge_cur, -1 * o.charge_amount)
      else
        raise StandardError.new('Not implemented operation')
      end

    elsif o.kind_of?(Expense)
      cur = o.cur.downcase

      total[cur] ||= 0
      total[cur] -= o.amount

      vpc.add_profit(cur, -1 * o.amount)
    end
  end
  vpc.clean_hash

  @result = {income: income, total: total, vpc: vpc.get_hash}
end

def convert_currency(rates, amount, cur1, cur2)
  cur1 = cur1.downcase
  cur2 = cur2.downcase

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

  slim :index
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

