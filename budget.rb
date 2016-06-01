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

  @budget_incomes = BudgetRecord.where(date: @date_start..@date_end, is_income: true).order(date: :asc)
  @budget_expenses = get_date_hash(BudgetRecord.where(date: @date_start..@date_end, is_income: false).order(date: :asc), :date)
end

