class AmountsOfIntegerType < ActiveRecord::Migration[6.1]
  def up
    Currency.all.each do |curr|
      multiplier = 10**curr.round

      say_with_time "Update income amounts for budget_records for #{curr.title}" do
        BudgetRecord.where(income_currency_id: curr.id).find_each do |br|
          br.update(income_amount: (br.income_amount * multiplier).round)
        end
      end

      say_with_time "Update expense amounts for budget_records for #{curr.title}" do
        BudgetRecord.where(expense_currency_id: curr.id).find_each do |br|
          br.update(expense_amount: (br.expense_amount * multiplier).round)
        end
      end

      say_with_time "Update monthly diffs for #{curr.title}" do
        MonthlyDiff.where(currency_id: curr.id).find_each do |md|
          md.update(amount: (md.amount * multiplier).round)
        end
      end
    end

    change_column :budget_records, :income_amount, :bigint, default: 0
    change_column :budget_records, :expense_amount, :bigint, default: 0
    change_column :monthly_diffs, :amount, :bigint, default: 0
    change_column :anchors, :total, :bigint, null: false
    change_column :anchors, :income, :bigint, default: 0
  end

  def down
    change_column :budget_records, :income_amount, :float, default: 0
    change_column :budget_records, :expense_amount, :float, default: 0
    change_column :monthly_diffs, :amount, :float, default: 0
    change_column :anchors, :total, :float, null: false
    change_column :anchors, :income, :float, default: 0

    Currency.all.each do |curr|
      multiplier = 10**(-1 * curr.round)

      say_with_time "Update income amounts for budget_records for #{curr.title}" do
        BudgetRecord.where(income_currency_id: curr.id).find_each do |br|
          br.update(income_amount: (br.income_amount * multiplier))
        end
      end

      say_with_time "Update expense amounts for budget_records for #{curr.title}" do
        BudgetRecord.where(expense_currency_id: curr.id).find_each do |br|
          br.update(expense_amount: (br.expense_amount * multiplier))
        end
      end

      say_with_time "Update monthly diffs for #{curr.title}" do
        MonthlyDiff.where(currency_id: curr.id).find_each do |md|
          md.update(amount: (md.amount * multiplier))
        end
      end
    end
  end
end
