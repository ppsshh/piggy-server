class DropSavingsTables < ActiveRecord::Migration
  def change
    drop_table :savings_exchanges
    drop_table :savings_account_charges
    drop_table :savings_expenses
    drop_table :savings_profits
    remove_column :budget_records, :record_type
  end
end
