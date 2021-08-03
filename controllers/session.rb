paths \
    session:  '/api/session',
    globals: '/api/globals'

post :session do
  halt(400, 'Blank login or password') if params['username'].blank? || params['password'].blank?
  halt(400, 'User not found') unless $config['admins'].present? && $config['admins'][params['username']].present?

  if $config['admins'][params['username']] == params['password']
    session['username'] = params['username']
  else
    halt(403, 'Access denied')
  end

  {username: params['username']}.to_json
end

delete :session do
  session.delete('username')
  {status: :ok}.to_json
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
    user: session['username'],
    tags: tags_array,
    default_currency_id: 3,
    currencies: Currency.all.index_by(&:id),
  }.to_json
end
