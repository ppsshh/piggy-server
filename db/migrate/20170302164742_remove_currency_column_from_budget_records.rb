class RemoveCurrencyColumnFromBudgetRecords < ActiveRecord::Migration[5.0]
  def change
    remove_column :budget_records, :currency
  end
end
