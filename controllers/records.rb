paths \
    records: '/api/records'

post :records do
  protect!

  BudgetRecord.create(params).to_json
rescue StandardError => e
  halt(400, "Unable to create record: #{e}")
end
