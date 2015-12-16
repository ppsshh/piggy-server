class DeleteIsIncomeFromCharges < ActiveRecord::Migration
  def change
    remove_column :account_charges, :is_income
  end
end
