class BudgetRecord < ActiveRecord::Base
end

class ExpenseType < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Currency < ActiveRecord::Base
  has_many :prices
end

class Price < ActiveRecord::Base
  belongs_to :currency
  class << self
    def closest(curr, date)
      c = Price.order(date: :desc).where(currency_title: curr).where("date <= ?", date).take
      c ||= Price.order(date: :asc).where(currency_title: curr).where("date >= ?", date).take
      return c
    end
  end
end

class Anchor < ActiveRecord::Base
end
