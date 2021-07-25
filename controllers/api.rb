paths \
    api_month: '/api/month/:year/:month',
    globals: '/api/globals'

get :api_month do
  protect!

  date_start = Date.new(params[:year].to_i, params[:month].to_i)
  date_end = date_start.end_of_month

  {
    operations: BudgetRecord
      .where(date: date_start..date_end, purse: [0, 1, 3])
      .each_with_object({}) {|br, acc| (acc[br.date] ||= []) << br},
    total: MonthlyDiff
      .where(date: ..date_end)
      .group(:currency_id)
      .sum(:amount)
      .filter {|k,v| v.abs > 0.0001},
  }.to_json
end

get :globals do
  protect!

  {
    tags: Tag.all.index_by(&:id),
    currencies: Currency.all.index_by(&:id),
  }.to_json
end
