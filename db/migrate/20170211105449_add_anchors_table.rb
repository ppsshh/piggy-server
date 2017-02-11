class AddAnchorsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :anchors do |t|
      t.date :date, null: false
      t.float :sum_old, null: false
      t.float :sum_new, default: 0

      t.timestamps null: false
    end
  end
end
