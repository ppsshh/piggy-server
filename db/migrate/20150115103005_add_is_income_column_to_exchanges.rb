class AddIsIncomeColumnToExchanges < ActiveRecord::Migration
  def change
    add_column :exchanges, :is_income, :boolean, default: true
  end
end
