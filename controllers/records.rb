paths \
    records: '/api/records',
    record: '/api/record/:id'

post :records do
  protect!

  br = BudgetRecord.find_or_initialize_by(id: params[:id])
  br.update!(params)
  br.to_json
rescue StandardError => e
  halt(400, "Unable to create/update record: #{e}")
end

delete :record do
  protect!

  br = BudgetRecord.find(params[:id])
  br.destroy!
rescue StandardError => e
  halt(400, "Unable to delete record: #{e}")
end
