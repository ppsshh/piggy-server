class AddShopField < ActiveRecord::Migration
  def change
    add_column :budget_records, :shop, :string
  end
end
