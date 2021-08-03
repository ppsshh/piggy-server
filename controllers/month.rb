paths api_month: '/api/month/:year/:month'

get :api_month do
  protect!

  date_start = Date.new(params[:year].to_i, params[:month].to_i)
  date_end = date_start.end_of_month

  {
    operations: BudgetRecord.where(date: date_start..date_end),
    totalsBefore: MonthlyDiff
      .where(date: ...date_start)
      .group(:currency_id)
      .sum(:amount)
      .filter {|k,v| v != 0},
    exrates: Currency.exrates(date_end),
  }.to_json
end
