class BudgetRecord < ActiveRecord::Base
  belongs_to :currency

  after_create :add_to_monthly_diff!
  before_update :fix_monthly_diff!
  before_destroy :rollback_monthly_diff!

  def fix_monthly_diff!
    rollback_monthly_diff!
    add_to_monthly_diff!
  end

  def rollback_monthly_diff!
    return if previous_value(:purse) == 2

    income_diff = MonthlyDiff.find_by(
      date: previous_value(:date).end_of_month,
      currency_id: previous_value(:income_currency_id),
    )
    income_diff.deduct!(previous_value(:income_amount)) if income_diff.present?

    expense_diff = MonthlyDiff.find_by(
      date: previous_value(:date).end_of_month,
      currency_id: previous_value(:expense_currency_id),
    )
    expense_diff.augment!(previous_value(:expense_amount)) if expense_diff.present?
  end

  def add_to_monthly_diff!
    return if purse == 2

    MonthlyDiff.find_or_create_by(
      date: date.end_of_month,
      currency_id: income_currency_id,
    ).augment!(income_amount) if income_currency_id

    MonthlyDiff.find_or_create_by(
      date: date.end_of_month,
      currency_id: expense_currency_id,
    ).deduct!(expense_amount) if expense_currency_id
  end

  def previous_value(key)
    changes.dig(key, 0) || send(key)
  end
end
