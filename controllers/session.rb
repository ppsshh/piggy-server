paths \
    session:  '/api/session'

get :session do
  halt(401, 'Access denied') unless current_user.present?
  current_user.to_json
end

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
