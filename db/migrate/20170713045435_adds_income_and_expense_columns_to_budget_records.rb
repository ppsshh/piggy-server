class AddsIncomeAndExpenseColumnsToBudgetRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :budget_records, :income_amount, :float, default: 0.0, null: false
    add_column :budget_records, :expense_amount, :float, default: 0.0, null: false
    add_column :budget_records, :income_currency_id, :integer
    add_column :budget_records, :expense_currency_id, :integer
  end
end
