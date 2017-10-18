class AddCurrencyTypeColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :currencies, :record_type, :string #currency, stock, crypto, etc?
  end
end
