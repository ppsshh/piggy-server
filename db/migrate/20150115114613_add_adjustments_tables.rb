class AddAdjustmentsTables < ActiveRecord::Migration
  def change
    create_table :profits do |t|
      t.date :date

      t.text :cur
      t.float :amount

      t.text :notes
      t.timestamps null: false
    end

    create_table :account_charges do |t|
      t.date :date

      t.text :target_cur
      t.text :charge_cur
      t.float :charge_amount

      t.text :notes
      t.timestamps null: false
    end

    create_table :expenses do |t|
      t.date :date

      t.text :cur
      t.float :amount

      t.text :notes
      t.timestamps null: false
    end
  end
end
