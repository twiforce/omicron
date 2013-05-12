class Motd < ActiveRecord::Base
  def self.set_new(message, moder_id)
    Motd.delete_all
    return Motd.create(message: message, moder_id: moder_id)
  end
end
