class CreateOperationsTable < ActiveRecord::Migration
  def change
    create_table :operations do |t|
      t.date :date

      t.text :sold_cur
      t.float :sold_amount

      t.text :bought_cur
      t.float :bought_amount

      t.text :notes

      t.timestamps
    end
  end
end
