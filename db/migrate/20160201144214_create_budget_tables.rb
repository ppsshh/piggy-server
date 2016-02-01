class CreateBudgetTables < ActiveRecord::Migration
  def change
    create_table :budget_expenses do |t|
      t.date :date, null: false
      t.float :amount, null: false, default: 0
      t.string :description
      t.timestamps null: false
    end

    create_table :budget_incomes do |t|
      t.date :date, null: false
      t.float :amount, null: false, default: 0
      t.string :description
      t.timestamps null: false
    end

    create_table :budget_savings do |t|
      t.date :date, null: false
      t.float :amount, null: false, default: 0
      t.string :description
      t.timestamps null: false
    end

    create_table :budget_daily_quotes do |t|
      t.date :date, null: false
      t.float :amount, null: false, default: 0
      t.timestamps null: false
    end
  end
end
