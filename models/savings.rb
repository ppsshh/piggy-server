class SavingsAccountCharge < ActiveRecord::Base
  def <=> (b)
    return self.date <=> b.date
  end
end

class SavingsExchange < ActiveRecord::Base
  def <=> (b)
    return self.date <=> b.date
  end
end

class SavingsExpense < ActiveRecord::Base
  def <=> (b)
    return self.date <=> b.date
  end
end

class SavingsProfit < ActiveRecord::Base
  def <=> (b)
    return self.date <=> b.date
  end
end
