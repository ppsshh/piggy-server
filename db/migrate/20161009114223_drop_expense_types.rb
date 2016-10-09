class DropExpenseTypes < ActiveRecord::Migration
  def change
    drop_table :expense_types
    remove_column :budget_records, :expense_type
  end
end
