paths \
    records: '/api/records'

def parse_amount(str)
  # TODO: remove hardcoded default currency
  default_currency_id = 3
  default_currency_title = 'JPY'

  return [0, default_currency_id] unless str&.strip&.present?

  match = str.match(/(?<digits>\d+(\.\d+)?)(?<text>.*)/)
  
  curr = Currency.where('title ILIKE ?', match[:text].strip.presence || default_currency_title).take!
  val = (match[:digits].to_f * 10**curr.round).to_i

  [val, curr.id]
rescue StandardError => e
  halt(400, "Unable to parse \"#{str}\": #{e}")
end

post :records do
  protect!

  br = BudgetRecord.new

  br.income_amount, br.income_currency_id = parse_amount(params[:income])
  br.expense_amount, br.expense_currency_id = parse_amount(params[:expense])

  br.date = Date.parse(params[:date])
  br.shop = params[:shop]
  br.tag_id = params.dig(:tag, :id).presence || 0
  br.description = params[:description].presence || ''
  br.save!

  :ok
rescue StandardError => e
  halt(400, "Unable to create record: #{e}")
end
