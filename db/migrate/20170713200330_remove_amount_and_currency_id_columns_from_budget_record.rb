class RemoveAmountAndCurrencyIdColumnsFromBudgetRecord < ActiveRecord::Migration[5.1]
  def change
    remove_column :budget_records, :amount
    remove_column :budget_records, :currency_id
  end
end
