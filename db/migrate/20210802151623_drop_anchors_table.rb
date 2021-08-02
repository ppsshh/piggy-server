class DropAnchorsTable < ActiveRecord::Migration[6.1]
  def up
    drop_table :anchors
  end
end
