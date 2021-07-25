class MonthlyDiff < ActiveRecord::Base
  belongs_to :currency

  def augment!(val)
    self.amount += val
    save!
  end

  def deduct!(val)
    self.amount -= val
    save!
  end
end
