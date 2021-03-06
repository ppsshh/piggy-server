paths autocomplete_shop: '/api/autocomplete/shop'

post :autocomplete_shop do
  protect!

  tr_query = params[:query].downcase.tr(
    "qwertyuiop[]asdfghjkl;'zxcvbnm,.`",
    "йцукенгшщзхъфывапролджэячсмитьбюё"
  )

  items = Operation.where.not(shop: '')
    .where('shop ILIKE ? OR shop ILIKE ?', "%#{params[:query]}%", "%#{tr_query}%")
    .order(shop: :asc).select(:shop).distinct.limit(20).pluck(:shop)

  items.to_json
end
