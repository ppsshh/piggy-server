class AddExpenseTypeColumn < ActiveRecord::Migration
def change
    add_column :budget_expenses, :expense_type, :integer, default: 0
  end
end
