paths \
    api_month:  '/api/month/:year/:month'

get :api_month do
  protect!

  date_start = Date.new(params[:year].to_i, params[:month].to_i)
  date_end = date_start.next_month

  {
    operations: BudgetRecord.where(date: date_start...date_end, purse: 0).each_with_object({}) do |br, acc|
      (acc[br.date] ||= []) << br
    end,
    savings: BudgetRecord.where(date: date_start...date_end, purse: 1),
  }.to_json
end
