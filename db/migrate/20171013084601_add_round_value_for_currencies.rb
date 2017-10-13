class AddRoundValueForCurrencies < ActiveRecord::Migration[5.1]
  def change
    add_column :currencies, :round, :integer, default: 2
  end
end
