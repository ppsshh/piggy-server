class BudgetRecord < ActiveRecord::Base
end

class ExpenseType < ActiveRecord::Base
end

class Tag < ActiveRecord::Base
end

class Currency < ActiveRecord::Base
  class << self
    def closest(curr, date)
      Currency.order(date: :desc).where(currency: curr).where("date <= ?", date).take
    end
  end
end

