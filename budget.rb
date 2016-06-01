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

def get_budget_data(month_delta = 0)
  @date_start = Date.today.beginning_of_month.prev_month(month_delta)
  @date_end = Date.today.end_of_month.prev_month(month_delta)

  @incomes = BudgetIncome.where(date: @date_start..@date_end).order(date: :asc)
  @expenses = get_date_hash(BudgetExpense.where(date: @date_start..@date_end).order(date: :asc), :date)
  @req_expenses = BudgetRequiredExpense.where(date: @date_start..@date_end).order(date: :asc)
end

