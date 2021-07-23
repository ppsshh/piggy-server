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
