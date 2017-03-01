module PiggyHelpers
  def currency_symbol(currency)
    currency = currency.to_s.downcase.to_sym
    currency_symbols = {
      usd: '$',
      eur: '€',
      jpy: '¥',
      rub: '₽'
    }

    return currency_symbols[currency.downcase] || currency.upcase
  end

  def money_format(amount, currency)
    parts = amount.round(2).to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1 ")
    parts.delete_at(1) if parts[1] == "0"

    return "#{parts.join('.')} #{currency_symbol(currency)}"
  end

  def cursym(cur)
    cur.to_s unless cur.kind_of?(String)
    return cur.downcase.to_sym
  end

  def convert_currency(rates, amount, cur1, cur2)
    cur1 = cur1.to_s.downcase
    cur2 = cur2.to_s.downcase

    if cur1 == 'usd'
      return amount if cur2 == 'usd'
      return amount / rates[cur2]
    elsif cur2 == 'usd'
      return rates[cur1] * amount
    else
      return rates[cur1] * amount / rates[cur2]
    end
  end

  def total_in_rub(savings, date = Date.today)
    rates = {}
    $config["currencies"].each do |c|
      rates[c] ||= Price.closest(c, date).rate
    end

    total_rub = 0
    ['usd', $config['currencies']].flatten.each do |c|
      amount = savings[c] ? savings[c] : 0
      total_rub += convert_currency(rates, amount, c, 'rub')
    end

    return total_rub
  end

  def tags
    _tags = {0 => {title: "NONAME"} }
    Tag.all.order(parent_id: :desc).each { |t| _tags[t.id] = {title: t.title, parent: t.parent_id} }
    return _tags
  end

  def calculate_anchor(date)
    d1 = date.beginning_of_month
    d2 = d1.next_month

    a = Anchor.find_or_initialize_by(date: d1)

    sum_old = BudgetRecord.where("purse = ? AND date < ?", 1, d1).group(:currency).sum(:amount)
    a.sum_old = total_in_rub(sum_old, d1)
    sum_new = BudgetRecord.where("purse = ? AND date >= ? AND date <= ?", 1, d1, d2).group(:currency).sum(:amount)
    a.sum_new = total_in_rub(sum_new, d2)

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
    while d <= Date.today
      calculate_anchor(d)
      d = d.next_month
    end
  end

end

