# -*- coding: utf-8 -*-

require 'net/http'
include ApplicationHelper

class ThreadsController < ApplicationController
  before_filter do 
    set_password
    set_cookies
    get_tag if ['index', 'page'].include?(params[:action])
  end

  def index
    if @tag == '~'
      @html_title = t('title.overview')
    else
      @html_title = @tag.name
    end
    set_captcha
    show_page(1)
  end

  def page
    if @tag == '~'
      @html_title = t('title.overview')
    else
      @html_title = @tag.name
    end
    @html_title += (' (стр. ' + params[:page] + ')')
    set_captcha
    show_page(params[:page].to_i)
  end

  def test
    @post = RPost.last
    output = Haml::Engine.new(File.read("#{Rails.root}/app/views/threads/_post.haml"))
    return render(json: {hui: 'pizda', post: output.render(Object.new, post: @post)})
  end

  def random # noone need this
    while true
      if RThread.count > 1
        rid = RThread.random.rid
        if rid != params[:not].to_i
          return redirect_to(rid: rid, action: 'show', format: 'html')
          break
        end
      else
        return redirect_to(action: 'index', trailing_slash: true)
        break
      end
    end
  end

  def create
    process_post
  end

  def reply
    process_post
  end

  def tags
  end

  def edit
    @post = RPost.get_by_rid(params[:rid].to_i)
    @post = RThread.get_by_rid(params[:rid].to_i) unless @post
    raise NameError if @post.created_at < (Time.now - 3.minutes)
    raise NameError if @post.password != cookies[:password]
    @thread = @post.r_thread if @post.kind_of?(RPost)
    if request.post?
      @post.message = parse(params[:message])
      @post.save
      return render(text: @post.message)
    else
      return render(text: parse_reverse(@post.message))
    end
  end

  def show
    unless (@thread = RThread.where(rid: params[:rid].to_i).first)
      if (post = RPost.get_by_rid(params[:rid].to_i))
        return redirect_to(action: 'show',    rid:    post.r_thread.rid,
                           anchor: "i#{post.rid}",  format: 'html')
      else
        return not_found
      end
    end
    set_captcha
    @seen = @user.seen[@thread.rid]
    @user.seen[@thread.rid] = @thread.replies_count
    unless [nil, 0].include?(@new_in_favorites)
      if @user.favorites.include?(@thread.rid) and @user.seen.has_key?(@thread.rid)
        @new_in_favorites -= (@thread.replies_count - @seen) if @seen - @thread.replies_count
      end
    end
    @post_counter = 0
    @html_title = @thread.title.dup
    @html_title = @thread.message.dup if @html_title.empty?
    @html_title.gsub!(/<(.+)?>/, ' ')
    @html_title = @html_title[0..43] + "..." if @html_title.length > 45
    @html_title += " (#{@thread.tags_names.join(', ')})"
  end

  def show_hack
    redirect_to(action: 'show', rid: params[:rid], format: 'html')
  end

  def get_post
    post = RPost.get_by_rid(params[:rid].to_i)
    thread = RThread.get_by_rid(params[:rid].to_i) unless post
    if post 
      render(partial: 'post', object: post)
    elsif thread
      render(partial: 'thread', object: thread)
    else
      render(text: '0')
    end
  end


  def hide_or_unhide
    post = RThread.get_by_rid(params[:rid].to_i)
    post = RPost.get_by_rid(params[:rid].to_i) unless post
    if post
      if @user.hidden.include?(post.rid)
        @user.hidden.delete(post.rid)
      else
        @user.hidden << post.rid
      end
      if post.kind_of?(RPost)
        return render(partial: 'post', object: post)
      else
        return render(partial: 'thread', object: post)
      end
    else
      return render(text: 'not found')
    end
  end

  def favorites
    @threads = RThread.where("r_threads.rid IN (?)", @user.favorites).order('bump DESC')
    @tag = '~'
    @html_title = t('interface.favorites')
    return render(template: 'threads/index')
  end 

  def toggle_fav
    if @user.favorites.include?(params[:rid].to_i)
      @user.favorites.delete(params[:rid].to_i)
    else
      if @user.favorites.size < 15
        @user.favorites << params[:rid].to_i
      else
        return render(text: 'fail')
      end
    end
    return render(text: 'success')
  end

  def delete
    @post = RPost.get_by_rid(params[:rid].to_i)
    @post = RThread.get_by_rid(params[:rid].to_i) unless @post
    return not_found unless @post
    logger.info "\n\n\n#{ajax?}\n\n\n"
    if request.post?
      @errors = Array.new
      @errors << 'Too old to delete' if @post.created_at < (Time.now - 3.minutes)
      @errors << t('errors.wont_delete_file') if @post.message.empty? and params[:file_only] == 'on'
      @errors << t('interface.bad_password') if @post.password != cookies[:password]
      if @errors.empty?
        if params[:file_only] == 'on' 
          @post.r_file.destroy
          @post.r_file_id = nil
          @post.save
          flash[:message] = t('flash.file_deleted') unless ajax?
        else
          @post.destroy
          flash[:message] = t('flash.post_deleted') unless ajax?
        end
        if ajax?
          return render(text: 'success')
        else
          rid = @post.rid
          if @post.kind_of?(RPost)
            redirect_to(action: 'show', rid: @post.r_thread.rid, 
                        anchor: "i#{@post.rid}", format: 'html')
          else
            redirect_to(action: 'index', tag: '~', trailing_slash: true)
          end
        end
      else
        return render(text: @errors.join('. ')) if ajax?
      end
    end
  end

  def refresh
    if request.post?
      if (thread = RThread.get_by_rid(params[:rid].to_i))
        timestamp = Time.at(params[:timestamp].to_i + 1) 
        posts = thread.r_posts.where("created_at >= ?", timestamp)
        unless posts.empty?
          @user.seen[thread.rid] = thread.replies_count
          return render(partial: 'post', collection: posts)        
        else
          return render(text: '0')
        end
      end
      render(text: number)
    else
      redirect_to(action: 'show', rid: params[:rid].to_i, format: 'html')
    end
  end

  def expand
    if request.post?
      if (thread = RThread.get_by_rid(params[:rid].to_i))
        posts = thread.r_posts.to_a
        @user.seen[thread.rid] = thread.replies_count
        if posts.empty?
          render(text: '0')
        else
          render(partial: 'post', collection: posts)
        end
      end
    else
      redirect_to(url_for(action: 'show', rid: params[:rid].to_i, format: 'html'))
    end
  end

  def live
    def get_last(after_rid)
      if after_rid == 0
        query = "created_at > ?", (Time.now - 20.minutes)
        posts = RPost.where(query).order("created_at DESC").limit(5).to_a
        threads = RThread.where(query).order("created_at DESC").limit(5).to_a
      else
        query = "rid > ?", after_rid
        logger.info  "\n\n\n#{query}\n\n\n"
        posts = RPost.where(query).order("created_at DESC").to_a
        threads = RThread.where(query).order("created_at DESC").to_a
      end
      content = posts + threads
      content.sort! { |x, y| y.rid <=> x.rid }
      return content
    end
    if request.post?
      content = get_last(params[:rid].to_i)
      return render(partial: 'live_update', object: content)
    else
      @html_title = "LIVE!"
      @content = get_last(RPost.last.rid - 15)
    end
  end

  private
  def ajax?
    params[:ajax] == 'enabled'
  end

  def get_tag
    if params[:tag] == '~'
      @tag = '~'
    else
      unless (@tag = Tag.where(alias: params[:tag]).first)
        not_found
      end
    end
  end

  def show_page(page_number)
    @user.hidden << 'hack' if @user.hidden.empty?
    if @tag == '~'
      if @user.settings[:full_hiding] != true
        @threads = RThread.order('bump DESC').includes(:tags).
        paginate(per_page: @user.settings[:threads_per_page], page: page_number)
      else
        hidden_rids = [31337] + @user.hidden
        Tag.all.each do |tag|
          if @user.hidden.include?(tag.alias)
            hidden_rids += tag.r_threads.pluck('r_threads.rid')
            logger.info "\n\n\nids: #{hidden_rids}\n\n\n"
          end
        end
        @threads = RThread.order('bump DESC').includes(:tags)
        .where("r_threads.rid NOT IN (?)", hidden_rids)
        .paginate(per_page: @user.settings[:threads_per_page], page: page_number)          
      end
    else
      if @user.settings[:full_hiding] != true
        @threads = RThread.order('bump DESC').joins(:tags).where("tags.alias = ?", @tag.alias)
        .paginate(per_page: @user.settings[:threads_per_page], page: page_number)
      else
        @threads = RThread.order('bump DESC').joins(:tags)
        .where("r_threads.rid NOT IN (?) AND tags.alias = ?", @user.hidden, @tag.alias)
        .paginate(per_page: @user.settings[:threads_per_page], page: page_number)
      end
    end
    if @threads.empty? and page_number != 1
      not_found
    else
      return render(template: 'threads/index')
    end
  end

  def set_password(check=false)
    if cookies.has_key?(:password) and not check
      @password = cookies[:password]
    else
      @password = (100000000 + rand(1..899999999)).to_s
      cookies[:password] =  { value:    @password,
                              path:     root_path, 
                              expires:  Time.new + 99999999 }
    end
  end

  def set_cookies
    cookies.delete(:go_from_show)  if cookies.has_key?(:go_from_show)
    cookies.delete(:go_from_index) if cookies.has_key?(:go_from_index)
    cookies.delete(:hidden_threads) if cookies.has_key?(:hidden_threads)
  end

  def process_post
    def validate_content
      @post.message.strip!
      if @p.spamtxt_enabled
        @p.spamtxt.each do |line|
          scan1 = @post.message.scan(line)
          scan2 = @ip.address.scan(line)
          unless (scan1.empty? and scan2.empty?)
            @p.spamtxt << Regexp.new(@post.password)
            @p.save
            raise TypeError
          end
        end
      end
      unless @post.valid?
        @post.errors.to_hash.each_value do |error_array|
          error_array.each { |e| @errors << e }
        end
      end
      if (file_result = validate_file).kind_of?(Array)
        @errors += file_result
      end
      regexp = /(\w|[й,ц,у,к,е,н,г,ш,щ,з,х,ъ,ф,ы,в,а,п,р,о,л,д,ж,э,я,ч,с,м,и,т,ь,б,ю])+/
      if @post.kind_of?(RThread)
        if (@post.message.scan(regexp).empty? and not @post.has_file?)
          @errors << t('errors.missing_content')
        else
          @errors << t('errors.missing_message') if @post.message.scan(regexp).empty?
          @errors << t('errors.missing_file') unless @post.has_file?
        end
        @tags = Array.new
        if @p.new_threads_to_trash
          @tags << Tag.where(alias: :trash).first
        elsif params[:tags].empty?
          @tags << Tag.where(alias: 'b')
        else
          params[:tags].split(' ').each do |t|
            if (tag = Tag.where(alias: t).first)
              @tags << tag
            else
              @errors << t('errors.tags_invalid')
              break
            end
          end
        end
      else
        unless (@post.has_file? or not @post.message.scan(regexp).empty?)
          @errors << t('errors.missing_content')
        end
      end
      unless @post.title.scan(/#(.*)?#/).empty?
        @post.title = ''
      end
      return @errors.empty?
    end

    def validate_file
      file = params[:message][:file]
      errors = Array.new
      @allowed = Array.new
      @p.allowed_file_types.each { |t| @allowed << t.split('/')[1].upcase }
      if (file == nil or file.kind_of?(String))
        unless (video = params[:video]).empty?
          video_id = params[:video].scan(/v=(.{10,12})(\&|\z|$)/)
          video_id = video_id[0] if video_id != nil
          video_id = video_id[0] if video_id != nil
          video_id = 'sosnooley' unless video_id
          url = URI.parse("http://gdata.youtube.com/feeds/api/videos/#{video_id}")
          req = Net::HTTP::Get.new(url.path)
          res = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
          if ['Invalid id', 'Video not found'].include?(res.body)
            @errors << t('errors.bad_video')
            return @errors.empty?
          else
            video_info = Hash.from_xml(res.body)
            video_params = {
              video_duration: video_info['entry']['group']['duration']['seconds'].to_i,
              video_title:    video_info['entry']['title'],
              filename:       video_id,
              md5_hash:       Digest::MD5.hexdigest(video_id),
              extension:      'video'
            }
            record = RFile.new(video_params)
            record.save
            @post.r_file_id = record.id
            return true
          end
        else
          return true
        end
      else
        if file.tempfile.size > @p.max_file_size
          errors << "#{t('errors.file_size_should_be')} #{@p.max_file_size/1024} kb."
        end
        if not @p.allowed_file_types.include?(file.content_type)
          errors << t('errors.file_type_should_be')
        end

        if errors.empty?
          hash = Digest::MD5.hexdigest(file.tempfile.read)
          if (h = RFile.where(md5_hash: hash).first)
            record = h.dup
            record.save
            @post.r_file_id = record.id
            if @post.kind_of?(RThread)
              @post.replies_files += 1
            else
              @thread.replies_files += 1
            end
            return true
          else
            type = file.content_type.split('/')[1]
            type = 'swf' if type == 'x-shockwave-flash'
            type = file.original_filename.split('.')[-1] if type == 'octet-stream'
            path = "#{Rails.root}/public/files"
            Dir::mkdir(path) if not File.directory?(path)
            filename = Time.now.to_i.to_s + rand(1000..9999).to_s
            path += "/#{filename}"
            thumb = "#{path}s"
            path += ".#{type}"
            thumb += ".#{type}"
            FileUtils.copy(file.tempfile.path, path)
            record_params = { 
              filename: filename, 
              md5_hash: hash, 
              extension: type, 
              size: file.tempfile.size,
            }
            this_is_pic = false
            begin
              pic = Magick::ImageList.new(path)
              this_is_pic = true if pic
            rescue 
              this_is_pic = false
            end
            if this_is_pic
              animated = (pic.length > 1)
              pic = pic[0]
              record_params[:rows] = pic.rows
              record_params[:columns] = pic.columns
              if (pic.columns > 200 or pic.rows > 200) or animated
                pic.resize_to_fit!(200, 200) 
                record_params[:resized] = true
                pic.write(thumb)
                record_params[:thumb_columns] = pic.columns
                record_params[:thumb_rows] = pic.rows
              end
            else
              record_params[:resized] = true
              record_params[:thumb_columns] = 128
              record_params[:thumb_rows] = 128
            end
            record = RFile.new(record_params)
            record.save
            @post.r_file_id = record.id
            if @post.kind_of?(RThread)
              @post.replies_files += 1
            else
              @thread.replies_files += 1
            end
          end
        else
          return errors
        end
      end
    end

    def validate_posting_permission
      if @ban
        @errors << 'banned'
        return @errors.empty?
      end
      if @post.kind_of?(RPost)
        checking = @ip.last_post
        limit = @p.reply_posting_speed
        if (@thread = RThread.get_by_rid(params[:rid].to_i))
          @post.r_thread_id = @thread.id
          @errors << t('errors.thread_closed') if @thread.closed
        else
          @errors << t('errors.thread_gone')
        end
      else
        last_created = RThread.order('created_at DESC').first.created_at
        delta = Time.now - last_created
        if delta < 60
          @errors << t('errors.thread_posting_limit') + (60 - delta.to_i).to_s
          return @errors.empty?
        end
        checking = @ip.last_thread
        limit = @p.thread_posting_speed
      end
      if (@ip.post_captcha_needed == true or @p.defence_mode or @enemy) and not moder?
        unless CaptchaController.validate(params[:captcha_word], session[:captcha_key])
          @errors << t('errors.captcha')
          return false
        end
      end
      @delta = Time.now - checking
      @errors << t('errors.posting_too_fast') if (@delta.to_i < limit) and not moder?
      return @errors.empty?
    end

    def send_reply(response)
      if response.kind_of?(Array)
        if response.include?('banned')
          url = url_for(controller: 'application', action: 'banned')
          return render(text: url, status: 302) if ajax?
          return redirect_to(url)
        end
        if ajax?
          render(partial: 'errors', status: 406)
        else
          render(template: 'threads/errors', status: 406)
        end
      else
        if response.kind_of?(RThread)
          url = url_for(action: 'show', rid: response.rid, format: 'html')
          if ajax?
            render(text: url, status: 302)
          else
            redirect_to(url, status: 302)
          end
        else
          url = url_for(action: 'show', rid: response.r_thread.rid, 
                        format: 'html', anchor: "i#{response.rid}")
          if ajax?
            render(partial: 'post', object: response, status: 201)
          else
            redirect_to(url, status: 302)
          end
        end
      end
    end

    @errors = Array.new
    params_dup = params[:message].dup
    params_dup.delete(:file)
    return render(text: '') if @p.spamtxt.include?(Regexp.new(params_dup[:password]))
    if params[:action] == 'create'
      logger.info "\nTrying to create new thread..."
      @post = RThread.new(params_dup)
    else
      logger.info "\nTrying to create new post..."
      @post = RPost.new(params_dup)
    end

    sleep(0.5) 
    validate_content if validate_posting_permission
    if @errors.empty?
      if params_dup[:password].empty?
        set_password(true)
      else
        @password = params_dup[:password]
      end
      @post.password = @password
      cookies[:password] =  { value:    @password,
                              path:     root_path, 
                              expires:  Time.new + 99999999 }
      @post.rid = IdCounter.get_next_rid(@post.kind_of?(RThread))                       
      @post.message = parse(@post.message)
      @post.message.strip!
      @post.ip_id = @ip.id
      if @post.kind_of?(RThread)
        @tags.each do |t|
          @post.tags << t
        end
      end
      @post.save
      if (@ip.post_captcha_needed == true) or moder?
        @ip.post_captcha_needed = false
      else
        if @post.kind_of?(RThread)
          checking = @ip.last_thread
          limit = 5.minutes
        else
          checking = @ip.last_post
          limit = 1.minute
        end
        delta = Time.now - checking
        logger.info delta.to_i
        logger.info limit
        if delta.to_i < limit
          @ip.post_captcha_needed = true 
          @show_captcha = true if @post.kind_of?(RPost)
        end
      end
      if @post.kind_of?(RPost)
        @ip.last_post = Time.now
        unless @post.sage or @thread.replies_count > @p.bump_limit
          @thread.bump = @post.created_at
        end
        @thread.replies_count += 1
        @thread.save
        @user.seen[@thread.rid] = @thread.replies_count
      else
        @ip.last_thread = Time.now
        if RThread.count > @p.max_threads
          RThread.order('bump DESC').last.destroy
        end
      end
      send_reply(@post)
    else
      send_reply(@errors)
    end
  end



  public
  def self.expire_board
    @p = SettingsRecord.first
    1.upto(RThread.count/@p.threads_per_page + 1) do |page|
      Rails.cache.delete("views/page_#{page}")
    end
  end
end

