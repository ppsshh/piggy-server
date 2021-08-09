class RenameBudgetRecordsToOperations < ActiveRecord::Migration[6.1]
  def change
    rename_table :budget_records, :operations
  end
end
