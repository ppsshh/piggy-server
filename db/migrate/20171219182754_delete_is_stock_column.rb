class DeleteIsStockColumn < ActiveRecord::Migration[5.1]
  def change
    remove_column :currencies, :is_stock, :boolean, default: :false
  end
end
