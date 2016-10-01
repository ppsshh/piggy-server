def get_days_range(d)
  dnext = d
  while dnext.day != $config['budget_start_day'] do dnext += 1 end
  dprev = d
  while dprev.day != $config['budget_start_day'] do dprev -= 1 end
  dprev = dprev.prev_month if dnext == dprev

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

def get_budget_data(year = Date.today.year, month = Date.today.month)
  @date_start = Date.new(year, month)
  @date_end = Date.new(year, month).next_month

  @budget_incomes = BudgetRecord.where(date: @date_start...@date_end, purse: 0).where("amount > 0").order(date: :asc)
  @budget_expenses = get_date_hash(BudgetRecord.where(date: @date_start...@date_end, purse: 0).where("amount < 0").order(date: :asc), :date)
  @budget_savings = BudgetRecord.where(date: @date_start...@date_end, purse: 1).order(date: :asc)
end

