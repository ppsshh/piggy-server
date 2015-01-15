class ChangeDateColumnsToDatetime < ActiveRecord::Migration
  def change
    change_column :exchanges, :date, :datetime
    change_column :profits, :date, :datetime
    change_column :account_charges, :date, :datetime
    change_column :expenses, :date, :datetime
  end
end
