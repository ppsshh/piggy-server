class MakeExpenseTypeStructureATree < ActiveRecord::Migration
  def change
    add_column :expense_types, :parent, :integer, default: 0
  end
end
