class AddMonthlyDiffsTable < ActiveRecord::Migration[6.1]
  def up
    create_table :monthly_diffs do |t|
      t.date :date
      t.float :amount, default: 0
      t.belongs_to :currency
      t.datetime :updated_at
    end

    say_with_time 'Creating MonthlyDiff records for every BudgetRecord' do
      BudgetRecord.find_each do |br|
        br.add_to_monthly_diff!
      end
    end
  end

  def down
    drop_table :monthly_diffs
  end
end
