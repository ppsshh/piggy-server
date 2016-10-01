class MergeBudgetAndSavingsTables < ActiveRecord::Migration
  def change
    add_column :budget_records, :purse, :integer, default: 0
    add_column :budget_records, :title, :string
    add_column :budget_records, :currency, :string, default: "rub"
  end
end
