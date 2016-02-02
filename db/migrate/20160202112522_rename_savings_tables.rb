class RenameSavingsTables < ActiveRecord::Migration
  def change
    rename_table :account_charges, :savings_account_charges
    rename_table :exchanges, :savings_exchanges
    rename_table :expenses, :savings_expenses
    rename_table :profits, :savings_profits
  end
end
