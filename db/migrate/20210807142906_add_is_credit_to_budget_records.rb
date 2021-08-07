class AddIsCreditToBudgetRecords < ActiveRecord::Migration[6.1]
  def change
    add_column :budget_records, :is_credit, :boolean, default: false
  end
end
