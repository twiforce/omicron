class SettingsController < ApplicationController
  before_filter :cookies_required, except: [:cookie_test]

  def index
    @html_title = t('interface.user_settings')
    if request.post?
      @errors = Array.new
      if (5..20).include?(params[:threads_per_page].to_i)
        @user.settings[:threads_per_page] = params[:threads_per_page].to_i
      else
        @errors << t('errors.settings.threads_per_page')
      end
      if (1..10).include?(params[:posts_per_thread].to_i)
        @user.settings[:posts_per_thread] = params[:posts_per_thread].to_i
      else
        @errors << t('errors.settings.posts_per_thread')
      end
      if @errors.empty?
        @user.settings[:show_up_button] = (params[:show_up_button] == 'on')
        @user.settings[:fixed_header] = (params[:fixed_header] == 'on')
        @user.settings[:scroll_after_post] = (params[:scroll_after_post] == 'on')
        @user.settings[:full_hiding] = (params[:full_hiding] == 'on')
        @user.settings[:autorefresh_enabled] = (params[:autorefresh_enabled] == 'on')
        @user.settings[:enable_maxwidth] = (params[:enable_maxwidth] == 'on')
        @user.settings[:enable_shadows] = (params[:enable_shadows] == 'on')
        @user.settings[:style] = params[:style]
        @user.settings[:fontsize] = params[:fontsize].to_i
        @user.settings[:fontsize] = nil if @user.settings[:fontsize] == 0
        @user.settings[:post_style] = params[:post_style]
        Tag.all.each do |tag|
          if params[:tags].has_key?(tag.alias)
            if params[:tags][tag.alias] == 'on'
              @user.hidden << tag.alias unless @user.hidden.include?(tag.alias)
            else
              @user.hidden.delete(tag.alias) if @user.hidden.include?(tag.alias)
            end
          else
            @user.hidden.delete(tag.alias) if @user.hidden.include?(tag.alias)
          end
        end
        @user.save
        flash[:message] = t('interface.settings_saved') 
      end
    end
  end

  def cookie_test 
    if cookies[:cookie_test].blank?
      @errors = [t('errors.cookies_required')]
      render(template: 'threads/errors')
    else
      redirect_to(action: 'index', trailing_slash: true)
    end
  end

  protected
  def cookies_required
    return true unless cookies[:cookie_test].blank?
    cookies[:cookie_test] = Time.now
    redirect_to(action: 'cookie_test')
  end
end
