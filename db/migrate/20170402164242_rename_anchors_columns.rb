class RenameAnchorsColumns < ActiveRecord::Migration[5.0]
  def change
    rename_column :anchors, :sum_old, :total
    rename_column :anchors, :sum_new, :income
  end
end
