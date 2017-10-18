class BudgetRecord < ActiveRecord::Base
  belongs_to :currency
end

class ExpenseType < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Currency < ActiveRecord::Base
  has_many :prices
  has_many :budget_records

  def is_currency?
    return record_type == "currency" ? true : false
  end

  def is_stock?
    return record_type == "stock" ? true : false
  end

  def is_crypto?
    return record_type == "crypto" ? true : false
  end
end

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

class Anchor < ActiveRecord::Base
end
