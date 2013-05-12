Omicron::Application.routes.draw do
  root :to => 'application#hack'
  match '/threads' => 'application#hack'

  scope '/' do
    match ':rid.:format'      => 'threads#show',                via: 'get',     constraints: {rid:  /\d+/, format: /html|xhtml/}
    match 'create'            => 'threads#create',              via: 'post'
    match 'random'            => 'threads#random',              via: 'get'
    match 'threads/:rid'      => 'threads#show_hack',           via: 'get',     constraints: {rid:  /\d+/}
    match ':rid/reply'        => 'threads#reply',               via: 'post',    constraints: {rid:  /\d+/}
    match ':rid/hide'         => 'threads#hide_or_unhide',      via: 'post',    constraints: {rid:  /\d+/}
    match ':rid/refresh'      => 'threads#refresh',                             constraints: {rid:  /\d+/}
    match ':rid/expand'       => 'threads#expand',                              constraints: {rid:  /\d+/}
    match ':rid/edit'         => 'threads#edit',                                constraints: {rid:  /\d+/}
    match ':tag/page/:page'   => 'threads#page',                via: 'get',     constraints: {page: /\d+/}
    match 'get_post'          => 'threads#get_post',            via: 'post'           
    match 'tags'              => 'threads#tags'
    match 'live'              => 'threads#live'
    match 'favorites'         => 'threads#favorites',           via: 'get'
    match ':rid/toggle_fav'   => 'threads#toggle_fav',          via: 'post',    constraints: {rid:  /\d+/}
  end
  match '/delete/:rid'        => 'threads#delete',                              constraints: {rid:  /\d+/}

  scope 'about' do 
    match ''                  => 'information#index'
    match 'engine'            => 'information#engine'
    match 'rules'             => 'information#rules'
    match 'contacts'          => 'information#contacts'
  end

  match '/settings'           => 'settings#index'            
  match '/settings/cookie-test' => 'settings#cookie_test'            

  match 'modlog'              => 'admin#show_logs',             via: 'get'
  scope 'admin' do
    match ''                 => 'admin#index'
    match 'defence'          => 'admin#defence_settings',       via: 'post'
    match 'spamtxt'          => 'admin#spamtxt',                via: 'post'
    match 'cleanup'          => 'admin#cleanup',                via: 'post'
    match 'view/post/:rid'   => 'admin#view_single',                            constraints: {rid: /\d+/}
    match 'view/:by'         => 'admin#view_many',                              constraints: {by: /.+/}
    match 'banhammer'        => 'admin#banhammer',              via: 'post'
    match 'update_tags/:rid' => 'admin#update_tags',            via: 'post',    constraints: {rid: /\d+/}
    match 'authorize'        => 'admin#authorize'
    match 'logout'           => 'admin#logout'
  end

  match '/captcha_gen'       => 'captcha#generate_image',      via: 'get'
  match '/captcha_refresh'   => 'captcha#refresh_image',       via: 'post'

  match '/banned'            => 'application#banned',          via: 'get'
  match '/:tag'              => 'threads#index',                via: 'get'
  match '*path'              => 'application#not_found'
end
