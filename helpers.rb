module PiggyHelpers
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

  def money_round(amount)
    parts = amount.round(2).to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1&nbsp;")
    #parts.delete_at(1) if parts[1] == "0"
    parts[1] += "0" if parts[1].length == 1

    return "#{parts[0]}<span class=\"cents\">.#{parts[1]}</span>"
  end

  def money_format(amount, currency_id)
    return "#{money_round(amount)}&nbsp;#{currency_symbol(currency_id)}"
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
    Tag.all.order(parent_id: :desc).each { |t| _tags[t.id] = {title: t.title, parent: t.parent_id} }
    return _tags
  end

  def calculate_anchor(date)
    d1 = date.beginning_of_month
    d2 = d1.prev_month

    a = Anchor.find_or_initialize_by(date: d1)

    total = BudgetRecord.where("purse = ? AND date < ?", 1, d1).group(:currency_id).sum(:amount)
    a.total = total_conversion(total, $main_currency, d1)
    income = BudgetRecord.where("purse = ? AND date >= ? AND date < ? AND is_conversion = ?", 1, d2, d1, false).group(:currency_id).sum(:amount)
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
      income = BudgetRecord.where("purse = ? AND date >= ? AND date < ?", 0, d1, d2).group(:currency_id).sum(:amount)
      income_main_currency = total_conversion(income, $main_currency, d2)
      a.income += income_main_currency
      a.total += income_main_currency
      a.save
    end
  end

end

