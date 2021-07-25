class Currency < ActiveRecord::Base
  has_many :prices
  has_many :monthly_diffs

  before_update :convert_amounts!, if: :round_changed?

  def convert_amounts!
    multiplier = 10**(round_change.last - round_change.first)

    BudgetRecord.where(income_currency_id: id).find_each do |br|
      br.update(income_amount: (br.income_amount * multiplier).round)
    end

    BudgetRecord.where(expense_currency_id: id).find_each do |br|
      br.update(expense_amount: (br.expense_amount * multiplier).round)
    end
  end
end
