class RemoveBudgetDailyQuotaTable < ActiveRecord::Migration
  def change
    drop_table :budget_daily_quota
  end
end
