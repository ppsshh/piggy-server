class RemovePurseFieldAndOthers < ActiveRecord::Migration[6.1]
  def change
    remove_column :budget_records, :purse, :integer, default: 0
    remove_column :prices, :updated_at, :datetime
    remove_column :prices, :date, :date
    remove_column :prices, :record_type, :integer, default: 0
  end
end
