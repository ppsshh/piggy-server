class Operation < ActiveRecord::Base
  belongs_to :income_currency, class_name: 'Currency', foreign_key: :income_currency_id
  belongs_to :expense_currency, class_name: 'Currency', foreign_key: :expense_currency_id
  belongs_to :tag

  validate :amounts_validator

  after_create :add_to_monthly_diff!
  before_update :fix_monthly_diff!
  before_update :set_conversion_flag
  before_destroy :rollback_monthly_diff!

  attr_writer :income, :expense, :tag

  scope :incomes, -> { where(income_amount: 1.., is_conversion: false) }
  scope :expenses, -> { where(expense_amount: 1.., is_conversion: false) }

  scope :group_sum, ->(sum_key, group_key1, group_key2) do
    group(group_key1, group_key2)
      .sum(sum_key)
      .each_with_object({}) do |kv,obj|
        k, amount = kv
        group_key1, group_key2 = k
        (obj[group_key1] ||= {})[group_key2] = amount
      end
  end

  def income=(str)
    self.income_amount, self.income_currency_id = parse_amount(str)
  end

  def expense=(str)
    self.expense_amount, self.expense_currency_id = parse_amount(str)
  end

  def tag=(tag_object)
    self.tag_id = tag_object&.dig(:id)
  end

  def amounts_validator
    return true if income_amount > 0 || expense_amount > 0

    errors.add(:base, 'Either expense or income amount must be greater than zero')
    false
  end

  def set_conversion_flag
    self.is_conversion = (income_amount && income_amount > 0 && expense_amount && expense_amount > 0)
  end

  def fix_monthly_diff!
    rollback_monthly_diff!
    add_to_monthly_diff!
  end

  def rollback_monthly_diff!
    MonthlyDiff.find_by(
      date: previous_value(:date).end_of_month,
      currency_id: previous_value(:income_currency_id),
    )&.deduct!(previous_value(:income_amount))

    MonthlyDiff.find_by(
      date: previous_value(:date).end_of_month,
      currency_id: previous_value(:expense_currency_id),
    )&.augment!(previous_value(:expense_amount))
  end

  def add_to_monthly_diff!
    MonthlyDiff.find_or_create_by(
      date: date.end_of_month,
      currency_id: income_currency_id,
    ).augment!(income_amount) if income_currency_id && income_amount != 0

    MonthlyDiff.find_or_create_by(
      date: date.end_of_month,
      currency_id: expense_currency_id,
    ).deduct!(expense_amount) if expense_currency_id && expense_amount != 0
  end

  def previous_value(key)
    changes.dig(key, 0) || send(key)
  end

  private

  def parse_amount(str)
    # TODO: remove hardcoded default currency
    default_currency_id = 3
    default_currency_title = 'JPY'
  
    return [0, default_currency_id] unless str&.strip&.present?
  
    match = str.match(/(?<digits>\d+(\.\d+)?)(?<text>.*)/)
    
    curr = Currency.where('title ILIKE ?', match[:text].strip.presence || default_currency_title).take!
    val = (match[:digits].to_f * 10**curr.round).to_i
  
    [val, curr.id]
  end
end
