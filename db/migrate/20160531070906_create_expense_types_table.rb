class CreateExpenseTypesTable < ActiveRecord::Migration
  def change
    create_table :expense_types do |t|
      t.text :description
      t.timestamps null: false
    end
  end
end
