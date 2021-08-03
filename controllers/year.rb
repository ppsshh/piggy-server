paths \
    api_year: '/api/year/:year',
    api_year_shop: '/api/year/:year/shop',
    api_year_tag: '/api/year/:year/tag/:id'

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
    exrates: Currency.exrates(Date.new(params[:year].to_i, 7)),
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
