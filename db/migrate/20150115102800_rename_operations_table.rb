class RenameOperationsTable < ActiveRecord::Migration
  def change
    rename_table :operations, :exchanges
  end
end
