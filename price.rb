class PriceConverter
  @prices = nil # {date1: {cur1: rate, cur2: rate, ...}, date2: {cur1: rate, ...}, ...}
  @currencies = nil # {cur1: [date1, date2, ...], cur2: [date1, ...], ...}
  @updated_at = nil
  @latest_reload = nil

  def initialize
    @updated_at = Date.new(1970, 1, 1)
    self.update
  end

  def reload
    @prices = {}
    @currencies = {}
    Price.where(record_type: [1,2]).order(updated_at: :desc).each do |p|
      @prices[p.date] ||= {}
      @prices[p.date][p.currency_id] = p.rate
      @currencies[p.currency_id] ||= []
      @currencies[p.currency_id] << p.date
    end

    @latest_reload = Time.now
  end

  def update
    p = Price.where(record_type: [1,2]).order(updated_at: :desc).take
    if @updated_at < p.updated_at
      @updated_at = p.updated_at
      self.reload
    end
    @latest_reload = Time.now
  end

  def get_rate(cur, date)
    if date == nil
      return @prices[@currencies[cur.id].sort.last][cur.id]
    elsif !@currencies.include?(cur.id)
      return nil
    elsif @currencies[cur.id].include?(date)
      return @prices[date][cur.id]
    end

    rate_day = nil
    @currencies[cur.id].sort.each do |d|
      rate_day = d
      break if d > date
    end

    if rate_day != nil
      return @prices[rate_day][cur.id]
    else
      return nil
    end
  end

  def convert_currency(cur1, cur2, amount, date = nil)
    return amount if cur1.id == cur2.id

    self.update if Time.now - @latest_reload > 60

    rate1 = get_rate(cur1, date)
    rate2 = get_rate(cur2, date)
    #puts "#### #{cur1.title} #{rate1}; #{cur2.title} #{rate2}"

    if cur1.title == 'USD'
      return amount if cur2.title == 'USD'
      return amount / rate2
    elsif cur2.title == 'USD'
      return rate1 * amount
    else
      return rate1 * amount / rate2
    end
  end
end
