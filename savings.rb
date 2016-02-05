include PiggyHelpers

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

