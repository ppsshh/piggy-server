class User < ActiveRecord::Base
  def password=(pwd)
    self.pwd_salt ||= SecureRandom.hex
    self.pwd_hash = Digest::SHA256.hexdigest(pwd + pwd_salt)
  end

  def password?(pwd)
    Digest::SHA256.hexdigest(pwd + pwd_salt) == pwd_hash
  end
end
