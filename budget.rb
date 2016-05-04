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

def get_budget_data(cur = Date.today)
  # d1 -- d2 -- today -- d3 -- d4
  d1, d2 = get_days_range(cur.prev_month)
  d3, d4 = get_days_range(cur.next_month)

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

