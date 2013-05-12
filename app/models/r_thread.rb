class RThread < ActiveRecord::Base
  has_and_belongs_to_many :tags
  has_many                :r_posts
  belongs_to              :r_file
  belongs_to              :ip

  serialize :replies_rids, Array

  validates_length_of   :message,   maximum: 5000
  validates_length_of   :title,     maximum: 60
  validates_length_of   :password,  maximum: 50

  before_create do
    ThreadsController::expire_board
    self.bump = Time.now
    self.replies_rids = []
  end

  after_create do 
    logger.info "Thread ##{self.rid} created."
  end

  before_destroy do
    ThreadsController::expire_board
    self.r_posts.each do |post| 
      post.destroy
    end
    self.r_file.destroy if self.r_file
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
    logger.info "\nThread ##{self.rid} destroyed."
  end

  def self.get_by_rid(rid)
    return self.where(rid: rid).first
  end

  def self.random
    uncached do
      return self.first(order: RANDOM)
    end
  end

  def has_file?
    return (self.r_file_id != nil)
  end

  def tags_aliases
    result = Array.new
    self.tags.each do |tag|
      result << tag.alias
    end
    return result
  end

  def tags_names
    result = Array.new
    self.tags.each do |tag|
      result << tag.name
    end
    return result
  end
end
