class MonthlyDiff < ActiveRecord::Base
  belongs_to :currency

  def augment!(val = 0)
    self.amount += val
    save!
  end

  def deduct!(val = 0)
    self.amount -= val
    save!
  end
end
