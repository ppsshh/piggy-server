class RenameBudgetExpensesTableToBudgetRecord < ActiveRecord::Migration
  def change
    rename_table :budget_expenses, :budget_records
  end
end
