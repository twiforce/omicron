class Ip < ActiveRecord::Base
  has_many :r_threads
  has_many :r_posts
  has_many :r_files

  has_one :ban

  before_create do
    self.thread_captcha_needed = true
    self.post_captcha_needed = true
  end

  def self.get(address)
    if (ip = Ip.where(address: address).first)
      logger.info "Got known IP ##{ip.id}."
    else
      ip = Ip.new
      ip.address = address
      ip.last_thread = Time.now - 600
      ip.last_post = Time.now - 600
      ip.save
      logger.info "Registered new IP ##{ip.id}."
    end
    return ip
  end

  def get_ban
    logger.info "\nChecking ban for IP ##{self.id}..."
    ban = self.ban
    logger.debug ban.inspect
    if ban
      if Time.now > ban.expires
        logger.info "IP was banned, but ban expired."
        ban.destroy
        return nil
      end
      logger.info "Yep, this IP is banned."
    else
      logger.info "Nope, this IP is clear."
    end
    return ban
  end

  def ban_ip(reason, expiration_date, moder_id)
    params = {
      reason:   reason,
      expires:  expiration_date, 
      ip_id:    self.id,
      level:    1,
      moder_id: moder_id
    }
    Ban.create(params)
  end
end
