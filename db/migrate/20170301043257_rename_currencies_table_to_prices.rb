class RenameCurrenciesTableToPrices < ActiveRecord::Migration[5.0]
  def change
    rename_table :currencies, :prices
  end
end
