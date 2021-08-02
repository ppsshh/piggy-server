module PiggyHelpers
  def protect!
    return if session['username'].present?

    halt 401, "Unauthorized"
  end
end
