class RFile < ActiveRecord::Base
  has_many :r_threads
  has_many :r_files

  before_destroy do
    logger.info "\nFile #{self.filename}.#{self.extension} destroyed."
    file_test = RFile.where(md5_hash: self.md5_hash).count
    unless file_test > 1
      begin 
        File.delete("#{Rails.root}/public#{self.url_full}")
        File.delete("#{Rails.root}/public#{self.url_small}")
      rescue
        # don't give a fuck
      end
    end
  end

  def picture?
    %w( png jpeg gif ).include?(self.extension)
  end

  def video?
    self.extension == 'video'
  end

  def flash?
    self.extension == 'swf'
  end

  def archive?
    ['zip', 'rar'].include?(self.extension)
  end

  def video_preview
    "http://i.ytimg.com/vi/#{self.filename}/0.jpg"
  end

  def url_full
    if self.video?
      "http://anonym.to/?http://youtube.com/watch?v=#{self.filename}"
    else
      "/files/#{self.filename}.#{self.extension}"
    end
  end

  def url_small
    if self.picture? and self.resized? 
      "/files/#{self.filename}s.#{self.extension}"
    elsif self.archive?
      "archive.png"
    elsif self.flash?
      "flash.png"
    else
      self.url_full
    end
  end
end
