paths \
    records: '/api/records'

post :records do
  protect!

  br = BudgetRecord.find_or_initialize_by(id: params[:id])
  br.update!(params)
  br.to_json
rescue StandardError => e
  halt(400, "Unable to create record: #{e}")
end
