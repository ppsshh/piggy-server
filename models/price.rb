class Price < ActiveRecord::Base
  belongs_to :currency
  class << self
    def closest(curr, date)
      c = Price.order(date: :desc).where(currency: curr).where("date <= ?", date).take
      c ||= Price.order(date: :asc).where(currency: curr).where("date >= ?", date).take
      return c
    end
  end
end
