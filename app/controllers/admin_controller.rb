class AdminController < ApplicationController
  before_filter :authorization_required, except: [:authorize, :show_logs]

  def index
    @html_title = t('interface.settings')
  end

  def spamtxt
    flash[:message] = ""
    @p.spamtxt_enabled = (params[:spamtxt_enabled] == 'on')
    flash[:message] += "Wipe filter: #{@p.spamtxt_enabled}<br />" if @p.changed?
    @p.spamtxt = Array.new
    params[:spamtxt].split("\n").each do |line|
      @p.spamtxt << Regexp.new(line.strip)
    end
    @p.save
    flash[:message] += "Wipe-filter updated"
    redirect_to(action: 'index', trailing_slash: true)
  end

  def defence_settings
    @p.defence_mode = (params[:defence] == 'on')
    @p.new_threads_to_trash = (params[:new_threads_to_trash] == 'on')
    @p.cookie_barrier = (params[:cookie_barrier] == 'on')
    @p.thread_posting_speed = params[:thread_posting_speed].to_i
    @p.reply_posting_speed = params[:reply_posting_speed].to_i
    @p.save
    flash[:message] = "Defence settings updated"
    redirect_to(action: 'index', trailing_slash: true)
  end

  def cleanup
    Captcha.delete_all
    flash[:message] = "All captchas deleted<br />"
    count = 0
    date = Time.now - 5.days
    User.where("updated_at <= ?", date).each do |user|
      user.destroy
      count += 1
    end
    flash[:message] += "#{count} users deleted<br />"
    date = Time.now - 2.days
    count = RPost.where("created_at <= ? AND ip_id IS NOT NULL", date).update_all(ip_id: nil)
    count += RThread.where("created_at <= ? AND ip_id IS NOT NULL", date).update_all(ip_id: nil)
    flash[:message] += "#{count} messages IP cleared"
    redirect_to(action: 'index', trailing_slash: true)
  end

  def logout
    @moder = nil
    session[:moder_id] = nil
    flash[:message] = t('flash.goodbye')
    redirect_to(:root)
  end

  def authorize
    if request.post?
      if CaptchaController::validate(params[:captcha_word], session[:captcha_key])
        if (@moder = Moder.authorize(params[:moder][:password]))
          session[:moder_id] = @moder.id
          flash[:message] = t('flash.login_successfull')
          return redirect_to(action: 'index', trailing_slash: true)
        else
          flash[:error] = t('errors.bad_login')
        end
      else
        flash[:error] = t('errors.captcha')
      end
    end
    set_captcha
    @html_title = t('interface.login')
  end

  def show_logs
    @html_title = t('interface.logs')
    @logs = AdminLogEntry.order('created_at DESC')
  end

  def view_single
    @html_title = t('interface.moderation')
    @post = RPost.get_by_rid(params[:rid].to_i)
    @post = RThread.get_by_rid(params[:rid].to_i) unless @post
    unless @post
      not_found
    end
  end

  def view_many
    @html_title = t('interface.moderation')
    if params[:by] == 'all'
      query = "created_at < ?", Time.now - 3.hours
    elsif (ip = Ip.where(address: params[:by]).first)
      query = { ip_id: ip.id }
    else
      query = { password: params[:by] }
    end
    @posts = RThread.where(query).order('created_at DESC').to_a
    @posts += RPost.where(query).order('created_at DESC').to_a
  end

  def banhammer
    rids = params[:posts]
    @errors = Array.new
    @errors << t('errors.no_reason') if params[:ban_reason] == nil
    @errors << t('errors.no_mod_action') unless params.has_value?('on')
    @errors << t('errors.invalid_days') if (params[:ban] != nil and params[:ban_days].to_i == 0)
    @errors << "no posts selected" if rids == nil 
    if @errors.empty?
      deleted_posts_rids = Array.new
      banned_posts_rids  = Array.new
      deleted_many       = 0
      rids.each_key do |post_rid|
        post = RPost.get_by_rid(post_rid.to_i)
        post = RThread.get_by_rid(post_rid.to_i) unless post
        if post
          if params[:delete_single] == 'on' and params[:delete_many] != 'on'
            deleted_posts_rids << post.rid
            post.destroy
          end
          if params[:delete_many] == 'on'
            date = Time.now - params[:minutes].to_i.minutes
            if post.ip_id != nil
              deleted_many =  post.ip.r_threads.where("created_at > ?", date).destroy_all.size
              deleted_many += post.ip.r_posts.where("created_at > ?", date).destroy_all.size
            end
          end
          if params[:ban] == 'on'
            banned_posts_rids << post.rid
            @p.spamtxt << post.password
            date = Time.now + params[:ban_days].to_i.days
            post.ip.ban_ip(params[:ban_reason], date, @moder.id) if post.ip
          end
        end
      end
      @p.save
      if not deleted_posts_rids.empty?
        log = Verbose::deleted_single(deleted_posts_rids, params[:ban_reason])
        AdminLogEntry.create(message: log, moder_id: @moder.id)
      elsif deleted_many > 0
        log = Verbose::deleted_many(rids[0], params[:minutes].to_i, params[:ban_reason])
        AdminLogEntry.create(message: log, moder_id: @moder.id)
      end
      unless banned_posts_rids.empty?
        log = Verbose::banned(banned_posts_rids, params[:ban_days].to_i, params[:ban_reason])
        AdminLogEntry.create(message: log, moder_id: @moder.id)
      end
      flash[:message] = t('interface.moderated')
      redirect_to(action: 'show_logs')
    else
      render('threads/errors')
    end
  end


  def update_tags
    if (thread = RThread.get_by_rid(params[:rid].to_i))
      thread.tags.clear
      params[:tags].split(' ').each do |tag|
        tag = Tag.where(alias: tag).first
        unless tag
          @errors = [t('errors.tags_invalid')]
          return render('threads/errors')
        else
          thread.tags << tag
        end
      end
      thread.save
      flash[:message] = "Tags updated"
      redirect_to(action: 'view_single', rid: thread.rid)
    else
      not_found
    end
  end  

  private
  def authorization_required
    @moder = Moder.find(session[:moder_id]) if moder? 
    unless @moder
      flash[:error] = t('errors.authorization_required')
      redirect_to(action: 'authorize')
    end
  en
end

