class AddCurrenciesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :currencies do |t|
      t.string :title
      t.string :description
      t.boolean :is_stock, default: :false
      t.boolean :update_regularly, default: false

      t.timestamps null: false
    end

    add_column :prices, :currency_id, :integer
  end
end
