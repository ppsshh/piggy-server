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

  def total_in_rub(savings)
    rates = {}
    $config["currencies"].each do |c|
      rates[c] ||= Currency.closest(c, Date.today).rate
    end

    total_rub = 0
    ['usd', $config['currencies']].flatten.each do |c|
      amount = savings[c] ? savings[c] : 0
      total_rub += convert_currency(rates, amount, c, 'rub')
    end

    return total_rub
  end
end

