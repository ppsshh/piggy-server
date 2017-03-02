class AddCurrencyIdColumnToBudgetRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :budget_records, :currency_id, :integer
  end
end
