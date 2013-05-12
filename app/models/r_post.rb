class RPost < ActiveRecord::Base
  belongs_to  :r_thread
  belongs_to  :r_file
  belongs_to  :ip

  serialize :replies_rids, Array

  validates_length_of :message,     maximum: 5000
  validates_length_of :title,       maximum: 60
  validates_length_of :password,    maximum: 50

  before_create do
    self.replies_rids = []
  end

  after_create do
    logger.info "Post ##{self.rid} created."
    ThreadsMailer.alert_sage(self).deliver if self.sage and self.has_file?
  end

  before_destroy do
    if (thread = self.r_thread)
      offset = thread.replies_count - 2
      offset = 0 if offset < 0
      previous = thread.r_posts.offset(offset).limit(1).first
      thread.bump = previous.created_at
      thread.replies_count -= 1
      thread.save
    end
    self.r_file.destroy if self.has_file?
    regexp = /<div class='post_link'><a href='.{3,25}\/(\d+).html#i(\d+)'>&gt;&gt;(\d+)<\/a><\/div>/
    self.message.scan(regexp).each do |link|
      post = RPost.where(rid: link[1].to_i).first
      post = RThread.where(rid: link[1].to_i).first unless post
      if post
        post.replies_rids.each do |hash|
          if hash[:post] == self.rid
            post.replies_rids.delete(hash)
          end
        end
        post.save
      end
    end
    logger.info "\nPost ##{self.rid} destroyed."
  end

  def self.get_by_rid(rid)
    return self.where(rid: rid).first
  end

  def has_file?
    return (self.r_file_id != nil)
  end
end
