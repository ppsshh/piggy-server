class AddsIsIncomeColumnToBudgetRecords < ActiveRecord::Migration
  def change
    add_column :budget_records, :is_income, :boolean, default: false
  end
end
