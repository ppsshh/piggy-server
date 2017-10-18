class AddPriceApiColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :currencies, :api, :jsonb
  end
end
