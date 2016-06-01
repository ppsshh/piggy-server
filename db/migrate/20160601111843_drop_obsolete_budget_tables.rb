class DropObsoleteBudgetTables < ActiveRecord::Migration
  def change
    drop_table :budget_incomes
    drop_table :budget_required_expenses
    drop_table :budget_savings
  end
end
