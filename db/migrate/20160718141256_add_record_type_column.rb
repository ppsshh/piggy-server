class AddRecordTypeColumn < ActiveRecord::Migration
  def change
    add_column :budget_records, :record_type, :integer, default: 0
  end
end
