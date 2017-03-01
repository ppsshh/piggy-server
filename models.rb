class BudgetRecord < ActiveRecord::Base
end

class ExpenseType < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Price < ActiveRecord::Base
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
