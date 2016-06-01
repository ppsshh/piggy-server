class AddsIsIncomeColumnToBudgetRecords < ActiveRecord::Migration
  def change
    add_column :budget_records, :is_income, :boolean, default: 0
  end
end
