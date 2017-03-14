class RemoveIsPermanentColumnFromPrices < ActiveRecord::Migration[5.0]
  def change
    remove_column :prices, :is_permanent, :boolean
  end
end
