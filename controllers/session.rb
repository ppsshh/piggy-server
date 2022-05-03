paths \
    session:  '/api/session',
    globals: '/api/globals'

post :session do
  halt(400, 'Blank login or password') if params['username'].blank? || params['password'].blank?

  user = User.find_by(username: params['username'])
  halt(403, 'Access denied') unless user.present? && user.password?(params['password'])

  session['username'] = params['username']

  { username: user.username }.to_json
end

delete :session do
  protect!

  session.delete('username')
  { status: :ok }.to_json
end

get :globals do
  protect!

  tags = Tag.all.index_by(&:id)
  tags_array = tags.transform_values do |v|
    {
      id: v.id,
      title: v.parent_id.present? ? "#{tags[v.parent_id].title}/#{v.title}" : v.title,
      image: v.image,
      parentId: v.parent_id,
      color: v.color,
    }
  end

  {
    user: current_user.username,
    memo: current_user.memo,
    tags: tags_array,
    default_currency_id: 3,
    currencies: Currency.all.index_by(&:id),
  }.to_json
end
