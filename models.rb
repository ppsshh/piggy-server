class BudgetRecord < ActiveRecord::Base
end

class ExpenseType < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Currency < ActiveRecord::Base
  class << self
    def closest(curr, date)
      c = Currency.order(date: :desc).where(currency: curr).where("date <= ?", date).take
      c ||= Currency.order(date: :asc).where(currency: curr).where("date >= ?", date).take
      return c
    end
  end
end

