class Exchange < ActiveRecord::Base
  def <=> (b)
    return self.date <=> b.date
  end
end
