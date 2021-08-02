paths \
    api_month: '/api/month/:year/:month',
    api_year: '/api/year/:year',
    api_year_shop: '/api/year/:year/shop',
    api_year_tag: '/api/year/:year/tag/:id',
    api_globals: '/api/globals'

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
    exrates: exrates(date_end),
  }.to_json
end

def exrates(date)
  Currency.all
    .each_with_object({}) {|c,obj| obj[c.id] = c.prices.knn(date) }
    .transform_values {|v| v.present? ? v.rate : nil }
end

get :api_year do
  protect!

  date_start = Date.new(params[:year].to_i)
  date_end = date_start.end_of_year

  {
    expenses: BudgetRecord.expenses
      .where(date: date_start..date_end)
      .group(:expense_currency_id, :tag_id)
      .sum(:expense_amount)
      .each_with_object({}) do |kv,obj|
        k, amount = kv
        curr, tag = k
        (obj[tag] ||= {})[curr] = amount
      end,
    incomes: BudgetRecord.incomes
      .where(date: date_start..date_end)
      .group(:income_currency_id, :tag_id)
      .sum(:income_amount)
      .each_with_object({}) do |kv,obj|
        k, amount = kv
        curr, tag = k
        (obj[tag] ||= {})[curr] = amount
      end,
    shops: BudgetRecord.expenses
      .where(date: date_start..date_end)
      .group(:shop, :expense_currency_id)
      .sum(:expense_amount)
      .each_with_object({}) do |kv,obj|
        k, amount = kv
        shop, curr = k
        (obj[shop] ||= {})[curr] = amount
      end,
    exrates: exrates(Date.new(params[:year].to_i, 7)),
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
      parentId: v.parent_id,
      color: v.color,
    }
  end

  {
    user: session['username'],
    tags: tags_array,
    default_currency_id: 3,
    currencies: Currency.all.index_by(&:id),
  }.to_json
end

get :api_year_shop do
  protect!

  date_start = Date.new(params[:year].to_i)
  date_end = date_start.end_of_year

  BudgetRecord.expenses
    .where(date: date_start..date_end)
    .where(shop: params[:shop].presence || ['', nil])
    .to_json
end

get :api_year_tag do
  protect!

  date_start = Date.new(params[:year].to_i)
  date_end = date_start.end_of_year

  BudgetRecord.expenses
    .where(date: date_start..date_end)
    .where(tag_id: params[:id])
    .to_json
end
