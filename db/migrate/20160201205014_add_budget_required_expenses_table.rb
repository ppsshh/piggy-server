class AddBudgetRequiredExpensesTable < ActiveRecord::Migration
  def change
    create_table :budget_required_expenses do |t|
      t.date :date, null: false
      t.float :amount, null: false, default: 0
      t.string :description
      t.timestamps null: false
    end
  end
end
