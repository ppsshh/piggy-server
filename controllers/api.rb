paths \
    api_month: '/api/month/:year/:month',
    globals: '/api/globals'

get :api_month do
  protect!

  date_start = Date.new(params[:year].to_i, params[:month].to_i)
  date_end = date_start.next_month

  {
    operations: BudgetRecord.where(date: date_start...date_end, purse: 0).each_with_object({}) do |br, acc|
      (acc[br.date] ||= []) << br
    end,
    savings: BudgetRecord.where(date: date_start...date_end, purse: [1, 2]),
  }.to_json
end

get :globals do
  protect!

  {
    tags: Tag.all.index_by(&:id),
    currencies: Currency.all.index_by(&:id),
  }.to_json
end
