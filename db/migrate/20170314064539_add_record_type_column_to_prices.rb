class AddRecordTypeColumnToPrices < ActiveRecord::Migration[5.0]
  def change
    add_column :prices, :record_type, :integer, default: 0
    # 0: default records
    # 1: 'permanent' records (beginning of the month)
    # 2: 'latest' records
  end
end
