class RemoveIsIncomeColumn < ActiveRecord::Migration
  def change
    remove_column :budget_records, :is_income
  end
end
