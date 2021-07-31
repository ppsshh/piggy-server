paths \
    api_month: '/api/month/:year/:month',
    api_globals: '/api/globals'

get :api_month do
  protect!

  date_start = Date.new(params[:year].to_i, params[:month].to_i)
  date_end = date_start.end_of_month

  {
    operations: BudgetRecord.where(date: date_start..date_end, purse: [0, 1, 3]),
    totalsBefore: MonthlyDiff
      .where(date: ...date_start)
      .group(:currency_id)
      .sum(:amount)
      .filter {|k,v| v != 0},
    exrates: Currency.all
      .each_with_object({}) {|c,obj| obj[c.id] = c.prices.knn(date_end) }
      .transform_values {|v| v.present? ? v.rate : nil }
  }.to_json
end

get :api_globals do
  protect!

  tags = Tag.all.index_by(&:id)
  tags_array = tags.transform_values do |v|
    {
      id: v.id,
      title: v.parent_id.present? ? "#{tags[v.parent_id].title}/#{v.title}" : v.title,
      image: v.image,
    }
  end

  {
    user: session['username'],
    tags: tags_array,
    default_currency_id: 3,
    currencies: Currency.all.index_by(&:id),
  }.to_json
end
