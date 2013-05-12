class Ban < ActiveRecord::Base
  belongs_to :ip

  before_create do 
    if (ban = self.ip.ban)
      ban.destroy
    end
  end

  before_destroy do
    logger.info "Ban ##{self.id} for IP ##{self.ip_id} destroyed."
  end
end
