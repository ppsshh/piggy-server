class RemoveTitleField < ActiveRecord::Migration
  def change
    remove_column :budget_records, :title
  end
end
