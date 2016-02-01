class RenameBudgetDailyQuotaTable < ActiveRecord::Migration
  def change
    rename_table :budget_daily_quotes, :budget_daily_quota
  end
end
