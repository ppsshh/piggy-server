class CreateCurrenciesTable < ActiveRecord::Migration
  def change
    create_table :currencies do |t|
      t.date :date
      t.text :currency
      t.float :rate

      t.timestamps
    end
  end
end
