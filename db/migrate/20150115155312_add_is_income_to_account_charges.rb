class AddIsIncomeToAccountCharges < ActiveRecord::Migration
  def change
    add_column :account_charges, :is_income, :boolean, default: false
  end
end
