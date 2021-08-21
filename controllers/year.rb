paths \
    api_year: '/api/year/:year',
    api_year_shop: '/api/year/:year/shop',
    api_year_tag: '/api/year/:year/tag/:id'

get :api_year do
  protect!

  scope = yearly_scope(params[:year].to_i)

  {
    expenses: scope.expenses.group_sum(:expense_amount, :tag_id, :expense_currency_id),
    incomes: scope.incomes.group_sum(:income_amount, :tag_id, :income_currency_id),
    shops: scope.expenses.group_sum(:expense_amount, :shop, :expense_currency_id),
    exrates: Currency.exrates(Date.new(params[:year].to_i, 7)),
  }.to_json
end

get :api_year_shop do
  protect!

  scope = yearly_scope(params[:year].to_i)

  {
    operations: scope.expenses.where(shop: params[:shop].presence || ['', nil]),
  }.to_json
end

get :api_year_tag do
  protect!

  scope = yearly_scope(params[:year].to_i)

  {
    operations: scope.expenses.where(tag_id: params[:id]),
  }.to_json
end

def yearly_scope(year)
  d = Date.new(year)
  Operation.where(date: d..d.end_of_year)
end
