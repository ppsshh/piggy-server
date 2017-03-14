class PricesTableRedesign < ActiveRecord::Migration[5.0]
  def change
    rename_column :prices, :date, :actual_date
    add_column :prices, :date, :date
    add_column :prices, :is_permanent, :boolean, default: false
  end
end
