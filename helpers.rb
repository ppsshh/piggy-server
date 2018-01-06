module PiggyHelpers
  def admin?
    session['role'] == 'admin'
  end

  def protect!
    return if admin?
    halt 401, "Unauthorized"
  end

  def currency_symbol(currency_id)
    currency = $currencies[currency_id]
    currency_symbols = {
      "USD" => '$',
      "EUR" => '€',
      "JPY" => '¥',
      "RUB" => '₽'
    }

    return currency_symbols[currency.title] || currency.title
  end

  def money_round(amount, currency_id)
    round_value = $currencies[currency_id] ? $currencies[currency_id].round : 2

    whole, fraction = sprintf("%.#{round_value}f", amount.round(round_value)).split('.')
    whole.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&nbsp;")
    #parts.delete_at(1) if parts[1] == "0"
    if round_value > 0
      fraction += "0" * (round_value - fraction.length) if round_value > 0
      fraction = "#{fraction[0..2]}<span class=\"microcents\">#{fraction[3..-1]}</span>"
      return "#{whole}<span class=\"cents\">.#{fraction}</span>"
    else
      return whole
    end
  end

  def money_format(amount, currency_id)
    return "#{money_round(amount, currency_id)}&nbsp;#{currency_symbol(currency_id)}"
  end

  def cursym(cur)
    cur.to_s unless cur.kind_of?(String)
    return cur.downcase.to_sym
  end

  def total_conversion(savings, curr, date, detailed = false)
    result = {
        src: savings,
        dst: {},
        total: 0}

    #puts "## #{date} #{savings}"
    $currencies.each do |i,c|
      amount = savings[c.id]
      if amount
        result[:dst][c.id] = $price_converter.convert_currency(c, curr, amount, date)
        result[:total] += result[:dst][c.id]
      end
    end
    #puts "## TOTAL: #{total} #{curr.title}"

    return detailed ? result : result[:total]
  end

  def tags
    _tags = {0 => {title: "NONAME"} }
    Tag.all.order(parent_id: :desc).each { |t| _tags[t.id] = {title: t.title, parent: t.parent_id, image: t.image} }
    return _tags
  end

  def income_expense_total(records)
    incomes = records.where("income_amount > 0").group(:income_currency_id).sum(:income_amount)
    expenses = records.where("expense_amount > 0").group(:expense_currency_id).sum(:expense_amount)
    expenses.each { |k,v| incomes[k] = (incomes[k] || 0) - v }
    return incomes  
  end

  def calculate_anchor(date)
    d1 = date.beginning_of_month
    d2 = d1.prev_month

    a = Anchor.find_or_initialize_by(date: d1)

    total = income_expense_total(
                BudgetRecord.where("purse = ? AND date < ?", 1, d1)
            )
    a.total = total_conversion(total, $main_currency, d1)

    income = income_expense_total(
                BudgetRecord.where("purse = ? AND date >= ? AND date < ? AND is_conversion = ?", 1, d2, d1, false)
            )
    a.income = total_conversion(income, $main_currency, d1)

    a.save
  end

  def recalculate_anchors
    d = $config['savings_start_date'].beginning_of_month
    while d <= Date.today
      calculate_anchor(d)
      d = d.next_month
    end
  end

  def update_anchors
    a = Anchor.order(date: :desc).take
    unless a
      recalculate_anchors
      return
    end

    d = a.date.prev_month.prev_month
# TODO: update only those months, where currency ratios have been changed/updated
    end_loop_date = Date.today.next_month
    while d <= end_loop_date
      calculate_anchor(d)
      d = d.next_month
    end

    # apply balance for current month (which is not in 'savings' yet)
    d1 = Date.today.beginning_of_month
    d2 = d1.next_month
    if a = Anchor.where(date: d2).take
      income = income_expense_total(
                BudgetRecord.where("purse = ? AND date >= ? AND date < ?", 0, d1, d2)
            )
      income_main_currency = total_conversion(income, $main_currency, d2)
      a.income += income_main_currency
      a.total += income_main_currency
      a.save
    end
  end

  def get_monthly_credit_payment(credit_amount, percents_per_year, credit_duration_years)
    # formula available at http://yurface.ru/kredit/annuitetnyj-platezh/
    percents_per_month = percents_per_year/12.0
    bp = 1/(1+percents_per_month)**(credit_duration_years*12) # bb is a 'bottom parenthesis'; part of expression for easier calculations
    monthly_payment = credit_amount * (percents_per_month / (1 - bp))
    return monthly_payment
  end

end

