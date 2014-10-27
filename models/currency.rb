class Currency < ActiveRecord::Base
  class << self
    def closest(curr, date)
      Currency.order(date: :desc).where(currency: curr).where("date <= ?", date).take
    end
  end
end
