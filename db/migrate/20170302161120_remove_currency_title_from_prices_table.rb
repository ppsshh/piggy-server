class RemoveCurrencyTitleFromPricesTable < ActiveRecord::Migration[5.0]
  def change
    remove_column :prices, :currency_title
  end
end
