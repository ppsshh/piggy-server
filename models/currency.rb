class Currency < ActiveRecord::Base
  has_many :prices
  has_many :monthly_diffs

  before_update :convert_amounts!, if: :round_changed?

  class << self
    def exrates(date)
      Currency.all
        .each_with_object({}) {|c,obj| obj[c.id] = c.prices.knn(date) }
        .transform_values {|v| v.present? ? v.rate : nil }
    end
  end

  def convert_amounts!
    multiplier = 10**(round_change.last - round_change.first)

    Operation.where(income_currency_id: id).find_each do |br|
      br.update(income_amount: (br.income_amount * multiplier).round)
    end

    Operation.where(expense_currency_id: id).find_each do |br|
      br.update(expense_amount: (br.expense_amount * multiplier).round)
    end
  end
end
