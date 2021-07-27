class Tag < ActiveRecord::Base
  has_many :budget_records
end
