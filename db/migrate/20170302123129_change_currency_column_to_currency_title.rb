class ChangeCurrencyColumnToCurrencyTitle < ActiveRecord::Migration[5.0]
  def change
    rename_column :prices, :currency, :currency_title
  end
end
