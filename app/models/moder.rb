class Moder < ActiveRecord::Base
  validates_presence_of     :hashed_password
  validates_uniqueness_of   :hashed_password
  validates_presence_of     :level

  attr_accessor   :password

  def password=(pass)
    @password = pass
    self.hashed_password = Moder.encrypt_password(@password)
  end

  def self.encrypt_password(password)
    return Digest::SHA1.hexdigest(password + SALT)
  end

  def self.authorize(password)
    logger.info "\nAuthorizing moder..."
    if (moder = where(hashed_password: Moder.encrypt_password(password)).first)
      logger.info "Successfully authorized moder withd ID ##{moder.id}"
      return moder
    else
      logger.info "Moder authorization failed"
      return nil
    end
  end
end
