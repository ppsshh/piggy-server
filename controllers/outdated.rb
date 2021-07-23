paths index: '/',
    budget: '/budget',
    budget_record: '/budget/record/:id',
    budget_year_month: '/budget/month/:year/:month',
    savings: '/savings',
    summary: '/summary/:year',
    tag_summary: '/summary/:year/:tag_id',
    global_tag_summary: '/summary2/:year/:tag_id',
    exrates: '/exrates',
    exrate_new: '/exrates/new',
    exrate: '/exrate/:id',
    graph: '/graph',
    hide_money: '/hide-money',
    set_theme: '/set-theme',
    autocomplete_shop: '/autocomplete/shop',
    mortgage: '/mortgage',
    prices_reload: '/prices_reload',
    css: '/main.css',
    login: '/login',
    logout: '/logout'

get :index do
  protect!
  redirect path_to(:budget_year_month).with(Date.today.year, Date.today.month)
end

get :budget do
  protect!
  redirect path_to(:budget_year_month).with(Date.today.year, Date.today.month)
end

def get_date_hash(items_array, date_key)
  h = {}
  items_array.each do |i|
    h[i[date_key]] ||= []
    h[i[date_key]] << i
  end
  return h
end

def get_budget_data(year = Date.today.year, month = Date.today.month)
  @date_start = Date.new(year, month)
  @date_end = Date.new(year, month).next_month

  @operations = get_date_hash(BudgetRecord.where(date: @date_start...@date_end, purse: 0), :date)
  @budget_savings = BudgetRecord.where(date: @date_start...@date_end, purse: 1).order(date: :asc)
end

get :budget_year_month do
  protect!

  $tags = tags
  y, m = params[:year].to_i, params[:month].to_i
  get_budget_data(y, m)
  @budget_date = Date.new(y, m)
  @savings = income_expense_total( BudgetRecord.where("purse = ? AND date < ?", 1, Date.new(y, m, 1)) )
  slim :budget
end

post :budget do
  protect!

  begin
    begin
      date = Date.parse(params[:date])
    rescue StandardError, ArgumentError
      flash[:error] = "Invalid date: #{params[:date]}"
      throw StandardError.new
    end

    op = BudgetRecord.new
    op.date = date

    op.income_amount = params[:income_amount]
    op.income_currency_id = params[:income_currency_id]
    op.expense_amount = params[:expense_amount]
    op.expense_currency_id = params[:expense_currency_id]

    op.is_conversion = params[:is_conversion] ? true : false
    op.description = params[:description]
    op.shop = params[:shop]
    op.tag_id = params[:tag_id].to_i
    op.purse = params[:purse].to_i
    op.save

    flash[:notice] = "Record successfully created"
  rescue StandardError
    flash[:error] ||= "Unable to create new record: #{params[:date]}, #{params[:income_amount]}, #{params[:expense_amount]} #{params[:description]} @ #{params[:shop]}, #{params[:operation_type]}"
  end

  redirect path_to(:budget_year_month).with(op.date.year, op.date.month)
end

get :graph do

  @operations = SavingsExchange.all

  slim :graph
end

get :budget_record do
  protect!
  @item = BudgetRecord.find(params[:id])
  slim :budget_item
end

post :budget_record do
  protect!
  item = BudgetRecord.find(params[:id])

  item.date = params[:date]

  item.income_amount = params[:income_amount]
  item.income_currency_id = params[:income_currency_id]
  item.expense_amount = params[:expense_amount]
  item.expense_currency_id = params[:expense_currency_id]

  item.is_conversion = params[:is_conversion] ? true : false
  item.description = params[:description]
  item.shop = params[:shop]
  item.tag_id = params[:tag_id].to_i
  item.purse = params[:purse].to_i
  item.save

  redirect path_to(:budget_year_month).with(item.date.year, item.date.month)
end

delete :budget_record do
  protect!
  item = BudgetRecord.find(params[:id])
  y, m = item.date.year, item.date.month

  item.destroy

  redirect path_to(:budget_year_month).with(y, m)
end

post :hide_money do
  if params["hide-money"] && params["hide-money"] == "true"
    request.session["hide-money"] = true
    return 200, '{"hide-money": true}'
  else
    request.session["hide-money"] = false
    return 200, '{"hide-money": false}'
  end
end

post :set_theme do
  request.session["theme"] = params["theme"]
  return 200, {theme: params["theme"]}.to_json
end

get :savings do
  protect!
  update_anchors
  @anchors = Anchor.all.order(date: :asc)

  slim :savings
end

get :summary do
  protect!
  @year = params[:year].to_i || Date.today.year
  expenses_by_tag = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0).where('expense_amount > 0').group(:tag_id, :expense_currency_id).sum(:expense_amount)

  expenses = {}
  expenses_sub = {}
  @tags = tags
  expenses_by_tag.each do |k,v|
    tag_id, currency_id = k
    tag_parent = @tags[tag_id][:parent] || tag_id

    v = $price_converter.convert_currency($currencies[currency_id], $main_currency, v) if currency_id != $main_currency.id

    expenses[tag_parent] = (expenses[tag_parent] || 0) + v

    expenses_sub[tag_parent] ||= {}
    expenses_sub[tag_parent][tag_id] ||= 0
    expenses_sub[tag_parent][tag_id]  += v
  end

  @expenses_sub = {}
  expenses_sub.each do |k,v|
    @expenses_sub[k] = expenses_sub[k].sort_by { |k,v| v }.reverse.to_h
  end

  @expenses = expenses.sort_by { |k,v| v }.reverse.to_h

# Get 'expenses by shop' data
  expenses_by_shop = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0).where('expense_amount > 0').group(:shop, :expense_currency_id).sum(:expense_amount)

  expenses = {}
  expenses_by_shop.each do |k,v|
    shop_name, currency_id = k
    v = $price_converter.convert_currency($currencies[currency_id], $main_currency, v) if currency_id != $main_currency.id
    expenses[shop_name] ||= 0
    expenses[shop_name] += v
  end

  @expenses_by_shop = expenses.sort_by { |k,v| v }.reverse.to_h

  slim :summary
end

get :tag_summary do
  protect!
  @year = params[:year].to_i || Date.today.year
  @tag = params[:tag_id].to_i

  @expenses = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0,
        tag_id: @tag).where(
        'expense_amount > 0').order(
        expense_amount: :desc)

  slim :tag_summary
end

get :global_tag_summary do
  protect!
  @year = params[:year].to_i || Date.today.year
  @tag = params[:tag_id].to_i
  tags = [@tag]
  Tag.where(parent_id: @tag).map {|t| tags << t.id}

  @expenses = BudgetRecord.where(
        date: (Date.new(@year, 1, 1)..Date.new(@year, 12, 31)),
        purse: 0,
        tag_id: tags).where(
        'expense_amount > 0').order(
        expense_amount: :desc)

  slim :tag_summary
end

get :autocomplete_shop do
  protect!
  term2 = params[:term].downcase.tr("qwertyuiop[]asdfghjkl;'zxcvbnm,.`", "йцукенгшщзхъфывапролджэячсмитьбюё")
  items = BudgetRecord.select(:shop).where('"shop" ILIKE ? OR "shop" ILIKE ?', "%#{params[:term]}%", "%#{term2}%").group(:shop).limit(10)
  items_array = []
  items.each { |i| items_array << i.shop }

  content_type :json
  items_array.to_json
end

get :mortgage do
  slim :mortgage
end

get :exrates do
  protect!
  redirect path_to(:exrate).with($main_currency.id)
end

get :exrate_new do
  protect!
  @currency = Currency.new
  @currency.api = {}
  slim :currency_new
end

def update_exchange(ex, params)
  ex.update(
        title: params['title'],
        description: params['description'],
        update_regularly: (params['update_regularly'] ? true : false),
        round: params['round'],
        record_type: params['record_type'],
        api: {
            url: params['api_url'],
            source: params['api_source'],
            inverse: (params['api_inverse'] ? true : false),
            referer: params['api_referer']
        }
    )
end

post :exrates do
  protect!
  ex = Currency.new
  update_exchange(ex, params)
  redirect path_to(:exrate).with(ex.id)
end

get :exrate do
  protect!
  @currency = Currency.find(params[:id])
  @prices = @currency.prices.order(actual_date: :desc)
  slim :exrate
end

post :exrate do
  protect!
  ex = Currency.find(params['id'])
  update_exchange(ex, params)
  redirect path_to(:exrate).with(ex.id)
end

get :prices_reload do
  protect!
  $price_converter.reload
  redirect path_to(:index)
end

get :css do
  protect!
  scss :main
end

get :login do
  if admin?
    flash[:notice] = "Already logged in"
    redirect path_to(:index)
  else
    slim :login
  end
end

post :login do
  if params['username'].blank? || params['password'].blank?
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  elsif $config['admins'] && $config['admins'][params['username']] == params['password']
    flash[:notice] = "Successfully logged in as admin!"
    session['role'] = 'admin'
    redirect path_to(:index)
  else
    flash[:error] = "Incorrect username or password :("
    redirect path_to(:login)
  end
end

delete :logout do
  session.delete('role')
  flash[:notice] = "Successfully logged out"
  redirect path_to(:index)
end
