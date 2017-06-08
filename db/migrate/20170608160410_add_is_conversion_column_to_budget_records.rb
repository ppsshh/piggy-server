class AddIsConversionColumnToBudgetRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :budget_records, :is_conversion, :boolean, default: false
  end
end
