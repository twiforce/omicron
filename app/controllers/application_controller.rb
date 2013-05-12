# -*- coding: utf-8 -*-
require 'socket'
require 'cgi/session'

class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter do
    return render(text: 'pisya', status: 405) unless verified_request?
    @start_time = Time.now.usec
    get_ip
    get_settings
    @hostname = Socket.gethostname
    @html_title = ''
    @enemy = Array.new
    file = File.open("#{Rails.root}/config/enemies.txt", 'r')
    file.each do |line|
      @enemy << line.strip
    end
    file.close
    @enemy = @enemy.include?(request.remote_ip)
    unless params[:controller] == 'captcha'
      authenticate
      @online = Ip.where(updated_at: (7.minutes.ago)..(Time.now)).size
      @posts_today = RPost.where(created_at: Time.now.at_midnight..Time.now).size
      @posts_today += RThread.where(created_at: Time.now.at_midnight..Time.now).size
      if cookies.has_key?(:_omicron_settings)
        set_user unless (@user = User.where(hashname: cookies[:_omicron_settings]).first)
      else
        set_user
      end
    end
  end

  after_filter do 
    unless params[:controller] == 'captcha'
      if @ip
        @ip.updated_at = Time.now
        @ip.save
      end
      if @user
        @user.updated_at = Time.now
        @user.save
      end
    end
  end

  def hack
    return redirect_to(controller: 'threads', action: 'index', tag: '~', trailing_slash: true)
    # if request.post?
    #   cookie = { value: "true" }
    #   cookie[:path] = root_path
    #   cookie[:expires] = Time.new + 99999999
    #   cookies[:eula_accepted] = cookie 
    #   if session.has_key?('redirect')
    #     r = session[:redirect].dup
    #     session[:redirect] = nil
    #     redirect_to(r)
    #   else
    #     redirect_to(controller: 'threads', action: 'index', tag: '~', trailing_slash: true)
    #   end
    # else
    #   if cookies.has_key?('eula_accepted')
    #     redirect_to(controller: 'threads', action: 'index', tag: '~', trailing_slash: true)
    #   else
    #     @html_title = 'EULA'
    #     render('eula')
    #   end
    # end
  end

  def not_found
    @html_title = '404'
    render('/not_found', status: 'not_found')
  end

  def banned
    redirect_to(:root) unless @ban
  end
  
  private
  def get_ip
    logger.info "\nRequesting IP record..."
    @ip = Ip.get(request.remote_ip.to_s)
    if (@ban = @ip.get_ban)
      if @ban.level == 2
        unless ['banned', 'create', 'reply'].include?(params[:action])
          redirect_to(controller: 'application', action: 'banned') 
        end
      end
    end
  end
  
  def set_user 
    if @p.cookie_barrier == true
      @user = User.new
      return render('application/cookie_barrier')
    else
      @user = User.create({
        hidden:   ['nsfw'],
        settings: {
          threads_per_page:   10,
          posts_per_thread:   6,
          show_up_button:     false,
        },
        seen:     Hash.new,
        favorites: Array.new
      })
      cookies[:_omicron_settings] = { 
        value:    @user.hashname,
        path:     root_path,
        expires:  Time.new + 99999999
      }
    end
  end

  def get_settings
    unless (@p = SettingsRecord.first)
      @p = SettingsRecord.new
      @p.allowed_file_types = ['image/png', 'image/jpeg', 'image/gif']
      @p.allowed_file_types += %w( application/x-rar-compressed application/zip application/x-shockwave-flash )
      @p.allowed_file_types << "application/octet-stream"
      @p.save
    end
  end

  def set_captcha
    mode = ((@enemy or false) or (@p.defence_mode or false))
    session[:captcha_key] = CaptchaController.get_captcha_key(mode)
  end

  def moder?
    session[:moder_id] != nil
  end

  def authenticate
    begin
      @moder = Moder.find(session[:moder_id]) if moder? 
    rescue Exception
      @moder = nil
      session[:moder_id] = nil
    end
  end

  def parse(text, processing_post=true)
    def bold(text)
      "<b>#{text}</b>"
    end

    def italic(text)
      "<i>#{text}</i>"
    end

    def strike(text)
      " <s>#{text}</s> "
    end

    def underline(text)
      "<u>#{text}</u>"
    end

    def spoiler(text)
      "<span class='spoiler'>#{text}</span>"
    end

    def quote(text)
      "<span class='quote'>&gt; #{text.strip}</span>"
    end

    def aquo(text)
      "&laquo;#{text}&raquo;"
    end

    def link(href, text)
      anon = ''
      unless href.include?('freeport7.org')
        anon = "http://anonym.to/?"
      end
      "<a href='#{anon + href}' target='_blank'>#{text}</a>"
    end

    # I'm sure that's a very bad practice, but fuck it
    text.strip!
    text.gsub!('&', '&amp;')
    text.gsub!(/<<(.+?)>>/,     aquo('\1'))
    text.gsub!('<', '&lt;')
    text.gsub!('>', '&gt;')
    text.gsub!('\'', '&#39;')
    text.gsub!(/\*\*(.+?)\*\*/, bold('\1'))
    text.gsub!(/\*(.+?)\*/,     italic('\1'))
    text.gsub!(/__(.+?)__/,     underline('\1'))
    text.gsub!(/(\s|^|\A)_(.+?)_(\s|$|\z)/,       strike('\2'))
    text.gsub!(/%%(.+?)%%/,     spoiler('\1'))
    text.gsub!('--',            '&mdash;')
    text.gsub!(/\[((http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,4}(\/\S*)?) \|\| (.+?)\]/, link('\1', '\4'))
    text.gsub!(/( |^)(http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,4}(\/\S*)?/) do |href|
      anon = ''
      href.strip!
      unless href.include?('freeport7.org')
        anon = "http://anonym.to/?"
      end
      " <a href='#{anon + href}' target='_blank'>#{href}</a> "
    end
    @id_counter = 0
    @new_references = []
    text.gsub! /&gt;&gt;(\d+)/ do |id|
      if @id_counter < @p.max_references_per_post
        @id_counter += 1
        id = id[8..id.length].to_i
        if @thread and id == @thread.rid
          post = @thread
        else
          post = RPost.get_by_rid(id)
          post = RThread.get_by_rid(id) if not post
        end
        if post
          if processing_post
            hash = {thread: @post.rid, post: @post.rid}
            hash[:thread] = @thread.rid if @post.kind_of?(RPost)
            post.replies_rids << hash unless post.replies_rids.include?(hash)
            @new_references << [post.rid, hash]
            post.save unless (@thread and post == @thread)
          end
          id = post.rid if post.kind_of?(RThread)
          id = post.r_thread.rid if post.kind_of?(RPost)
          url = url_for(controller: 'threads', action: 'show',
                        rid: id,  anchor: "i#{post.rid}", format: 'html')
          "<div class='post_link'><a href='#{url}'>&gt;&gt;#{post.rid}</a></div>"
        else
          "&gt;&gt;#{id}"
        end
      else
        "&gt;&gt;#{id}"
      end
    end
    if processing_post
      @id_counter = 0
      text.gsub! /##(\d+)/ do |id|
        result = "#{id}"
        if @id_counter < @p.max_references_per_post
          @id_counter += 1
          id = id[2..id.length].to_i
          post = RPost.get_by_rid(id)
          post = RThread.get_by_rid(id) if not post
          if post
            if post.password == @post.password
              id = post.rid if post.kind_of?(RThread)
              id = post.r_thread.rid if post.kind_of?(RPost)
              url = url_for(controller: 'threads',
                            action:     'show',
                            rid:        id,
                            anchor:     "i#{post.rid}",
                            format:     'html')
              result = "<div class='proofmark'><a href='#{url}'>###{post.rid}</a></div>"
            end
          end
        end
        result
      end
      if @post.kind_of?(RPost)
        text.gsub! /##(OP)|##(ОП)|##(op)|##(оп)/ do |op|
          if @post.password == @thread.password
            url = url_for(action: 'show', rid: @thread.rid,
                         anchor: "i#{@thread.rid}", format: 'html')      
            "<div class='proofmark'><a href='#{url}'>#{op}</a></div>"
          else
            "##OP"
          end
        end
      end
      if moder?
        text.gsub!("##ADMIN", "<span class='admin_proofmark'>##ADMIN</span>") if @moder.level == 3
      end
    end
    text.gsub!(/^&gt;(.+)$/,  quote('\1'))
    text.gsub!(/\r*\n(\r*\n)+/, '<br /><br />')
    text.gsub!(/\r*\n/,        '<br />')
    return text
  end
end
   