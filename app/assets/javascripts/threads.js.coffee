highlighted_post = null
post_to_update = null
need_to_update = true
pView = null
qr_form = null
disclaimer = null
reply_button = null
popup = null
live_processing = false
mouse_over_element = null
previous_hash = document.location.hash

$(document).ready ->
  popup = $('#popup_message')
  if popup.html() != undefined
    s = document.cookie.search('popup_closed')
    if s != -1
      popup.css('display', 'none')
    else
      $('#close_popup').click(close_popup)
  set_dropdowns()
  $(window).resize ->
    set_dropdowns()
    width = document.body.clientWidth
    $('.pic_url img').css('max-width', "#{width-90}px")
  $('#up_button').click(go_up)
  $('#down_button').click(go_down)
  if controller == 'threads'
    $('.expand_button').unbind().click(expand_thread) 
    $('#bottom_menu').css('display', 'block')
    reply_button = $('#reply_button')
    $('.ajax_detector').attr('value', 'enabled')
    if document.location.hash != ''
      highlight_post(document.location.hash.substring(2))
    unless $.browser.opera
      $('#qr_form textarea').bind('keydown', 'ctrl+return', -> $('#qr_form').submit()) 
    $('.editbox b').click(bold)
    $('.editbox i').click(italic)
    $('.editbox u').click(underline)
    $('.editbox s').click(strike)
    $('.editbox .spoiler').click(spoiler)
    $('.editbox .quote').click(quote)
    $('.editbox a.link_tag').click(link)
    $('#refresh_button').click(refresh_thread)
    qr_form = $('#qr_form')
    disclaimer = qr_form.find('.disclaimer')
    top = parseInt((window.innerHeight / 100) * 30)
    #qr_form.css({'position': 'fixed', 'right': '-700px', 'top': top + 'px'}).data('shown', false)
    right = -(qr_form.width() + 50)
    bottom = $('#bottom_menu').height() + 10

    qr_form.css({'position': 'fixed', 'right': right, 'bottom': bottom}).data('shown', false)
    if action == 'index' or action == 'page' or action == 'live' or action == 'favorites'
      disclaimer.html('Создать новый тред')
    else
      disclaimer.html('Ответить в тред #')
      thread = $('#thread_container').find('.thread').attr('id')
      disclaimer.html(disclaimer.html() + thread.substring(1))      
    reply_button = $('#reply_button')
    reply_button.click(toggle_qr_form)
  if $("#flash_message").html() != null
    f = $("#flash_message")
    f.animate({opacity: 0}, 5500)
    hui = ->
      f.css('display', 'none')
    setTimeout(hui, 6000)
  $('#tags').click -> 
    return false
  $('.captcha_field img').click ->
    refresh_captcha($(this))
  if up_button_enabled
    if controller == 'threads'
      check_up_button()
      $(window).scroll(check_up_button)
  if controller == 'threads' and action == 'show'
    setInterval(refresh_thread, 30000)  if autorefresh_enabled == true
    setInterval ->
      if document.location.hash != previous_hash
        post = $(document.location.hash)
        if post.html() != undefined
          highlight_post(post.attr('id').substring(1)) 
      previous_hash = document.location.hash
    , 300
  if controller == 'threads' and action == 'live'
    setInterval(refresh_live, 4000)
  strip_text()
  rebind()

rebind = ->
  width = document.body.clientWidth
  $('.pic_url img').css('max-width', "#{width-90}px")
  $('.post_header .post_link, .qr_link').unbind().click(show_qr_form)
  $('#qr_form').unbind().submit(submit_form)
  $('.pic_url').unbind().click(show_picture_original)
  $('.video_url').unbind().click(show_video)
  $('.hide_button').unbind().click(hide)
  $('blockquote .post_link, .replies_rids .post_link, .proofmark, .context_link').unbind().hover(show_post_preview, preview_link_out)
  $('#file_span, #video_span').unbind().click(toggle_file_video)
  $('.file_container').hover(show_file_info, hide_file_info)
  $('.expand_text_button').unbind().click(expand_text)
  $('.post_container, .thread_container .thread').unbind().hover(show_delete_button, hide_delete_button)
  $('.preview').unbind().hover(preview_over, preview_out)
  $('.manage_button').unbind().click(show_manage_menu).hover(sosnooley, hide_manage_menu)
  $('.manage_menu').unbind().hover(mouse_over, hide_manage_menu)
  $('.fav_button').unbind().click(toggle_fav)
  $('.delete_button, .delete_file_button').unbind().click(delete_post)
  $('.edit_button').unbind().click(edit_post)
  $.each $('.fav_button'), (object, div) ->
    $(div).data('on', ($(div).find('img').attr('src').search('gold') != -1))
  return false

set_dropdowns = ->
  $('#tags').unbind().hover(show_dropdown, hide_dropdown)
  taglist = $('#taglist')
  taglist.unbind().hover(mouse_over, hide_dropdown)
  tags_offset = $('#tags').offset().left
  taglist.css('left', tags_offset - taglist.width()/2).css('top', -(taglist.height() + 50))
  taglist.css('display', 'table')


toggle_qr_form = ->
  if qr_form.data('shown')
    hide_qr_form()
  else
    show_qr_form('click')
  return false

hide_qr_form = ->
  qr_form.find('input').blur()
  qr_form.find('textarea').blur()
  qr_form.animate({right: -700}, 400)
  qr_form.data('shown', false)
  reply_button.html(reply_button.data('initial_title'))
  return false



toggle_file_video = ->
  $(this).addClass('selected')
  if $(this).attr('id') == 'file_span'
    $('#video_span').removeClass('selected')
    $(this).parent().find('.video_field').css('display', 'none')
    $(this).parent().find('.file_field').css('display', 'inline').focus()
  else
    $('#file_span').removeClass('selected')
    $(this).parent().find('.file_field').css('display', 'none')
    $(this).parent().find('.video_field').css('display', 'inline').focus()


show_qr_form = (reason=null) ->
  pView = 'showing...'
  selected_text = getSelectedText()
  qr_form.css('display', 'table')
  if $.browser.chrome
    qr_form.animate({right: 25}, 400)
  else
    qr_form.animate({right: -10}, 400)
  qr_form.data('shown', true)
  reply_button.data('initial_title', reply_button.html())
  reply_button.html('закрыть форму')
  textarea = qr_form.find('textarea')
  if $(this).hasClass('post_link') or $(this).hasClass('qr_link')
    post = parents_until($(this), ['post', 'thread'])
    post_id = post.attr('id').substring(1)
    if post.hasClass('post')
      thread_id = post.attr('thread')
    else
      thread_id = post.attr('id').substring(1)
    if action == 'index' or action == 'page' or action == 'live' or action == 'favorites'
      disclaimer.html("Ответить в тред ##{thread_id}")
      qr_form.data('replying_to', thread_id)
      qr_form.attr('action', "/#{thread_id}/reply")
      qr_form.find('#form_tags').css('display', 'none')
      qr_form.find('#sage').css('display', 'inline-block')
    textarea.focus()
    textarea.val("#{textarea.val()}>>#{post_id}\n")
  else
    textarea.focus()
    if action == 'show'
      qr_form.data('replying_to', $('#thread_container').find('.thread').attr('id').substring(1))
    else
      disclaimer.html("Создать новый тред")
      qr_form.data('replying_to', 0)
      qr_form.attr('action', "/create")
      qr_form.find('#form_tags').css('display', 'inline-block')
      qr_form.find('#sage').css('display', 'none')
  if selected_text.length > 0
    textarea.focus()
    textarea.val("#{textarea.val()}> #{selected_text}\n")
  if qr_form.find('.captcha_field').css('display') != 'none'
    if qr_form.find('.captcha_image').attr('src') == '/favicon.ico'
      refresh_captcha(qr_form.find('.captcha_image'), false)
  return false



submit_form_callback = ->
  if refresh_thread.done == true
    h = post_to_update 
    post_to_update = null
    post = $("##{h}").parent()
    highlight_post(post.find('.post').attr('id').substring(1))
    $.scrollTo(post, 200, {offset: {top: -150}}) if scroll_after_post
    setTimeout(post.animate({opacity: 1}, 1300), 400)

submit_form = ->
  button = qr_form.find('.submit_button')
  errors = qr_form.find('.errors')
  captcha_field = qr_form.find('.captcha_field')
  captcha_image = captcha_field.find('img')
  vf = $('#video_span').parent().find('.video_field')
  if vf.css('display') != 'none'
    file = qr_form.find('.file_field')
    file.parent().html(file.parent().html())
  else
    $('.video_field').val('')
  if qr_form.data('replying_to') != 0
    thread_container = $("#i#{qr_form.data('replying_to')}").parent()
  qr_form.ajaxSubmit
    before_submit: blur_form(qr_form)
    success: (response) ->
      unblur_form(qr_form)
      clear_form(qr_form)
      errors.html('')
      captcha_field.css('display', 'none')
      captcha_image.attr('src', '/favicon.ico')
      hide_qr_form()
      if $(response).find('.i_need_captcha').html() != undefined
        captcha_field.css('display', 'block')
        refresh_captcha(captcha_image, false)
      if action == 'live'
        refresh_live()
        return false
      if action == 'show'
        post_to_update = $(response).find('.post').last().attr('id')
        refresh_thread()
      else
        post = $(response).css('opacity', 0)      
        thread_container.append(post)
        increase_replies_count(1)
        update_references(post)
        rebind()
        $.scrollTo(post, 200, {offset: {top: -250}})
        setTimeout ->
         post.animate({opacity: 1}, 1300)
        , 400
        need_to_update = true
      return false
    error: (response) ->
      if response.status == 302
        document.location = response.responseText
      else
        errors.html(response.responseText)
        errors.html('Неизвестная ошибка. Проверьте соединение.') if errors.html() == ''
        unblur_form(qr_form)
        captcha_errors = qr_form.find('.errors:contains("Проверочный код")')
        captcha_field.css('display', 'block') if captcha_errors.html() != undefined
        refresh_captcha(captcha_image) if captcha_field.css('display') != 'none'
      return false
  return false


offset = (el, xy) ->
  c = 0
  while el
    c += el[xy]
    el = el.offsetParent
  return c

preview_link_out = ->
  link = $(this)
  #father = link.parent().parent().parent()
  #father = father.parent() if father.hasClass('post')
  father = parents_until(link, ['thread', 'post']).parent()
  if father.hasClass('preview')
    pView = father
    setTimeout ->
      unless pView.hasClass('post_link') or pView.hasClass('context_link')
        procceed = true
        while procceed == true
          sibling = pView.next()
          if sibling.html() != undefined
            sibling.remove() 
          else
            procceed = false
    , 300
  else
    pView = null
    setTimeout ->
      $('#previews').html('') if pView == null
    , 300
  return false

preview_over = ->
  pView = $(this)
  return false

preview_out = ->
  pView = null
  setTimeout ->
    if pView != null
      unless pView.hasClass('post_link') or pView.hasClass('context_link')
        procceed = true
        while procceed == true
          sibling = pView.next()
          if sibling.html() != undefined
            sibling.remove()
          else
            procceed = false
    else
      $('#previews').html('')
  , 400
  return false

show_post_preview = (e) ->
  father = $(this).parent()
  if (father.is('blockquote') or father.hasClass('replies_rids')) or $(this).hasClass('context_link')
    pView = $(this)
  else
    return false
  link = $(this).find('a')[0]
  pNum = link.hash.match(/\d+/)
  scrW = document.body.clientWidth
  scrH = window.innerHeight
  x = offset(link, 'offsetLeft') + link.offsetWidth / 2
  y = offset(link, 'offsetTop')
  y += link.offsetHeight if (e.clientY < scrH*0.75) 
  pViewLocal = $("<div class='preview' id='preview_#{pNum}'><p>Загружаем...</p></div>")
  style = 'position:absolute; z-index:300;'
  if x < scrW/2
    style += 'left:' + x + 'px; '
  else 
    style +='right:' + parseInt(scrW - x + 2)  + 'px; '
  if e.clientY < scrH*0.75
    style += 'top:' + y   + 'px; '
  else 
    style += 'bottom:' + parseInt(scrH - y - 4) + 'px; '
  pViewLocal.attr('style', style)
  $('#previews').append(pViewLocal)
  from_post = parents_until($(this), ['thread', 'post']).attr('id').substring(1)
  pViewLocal.data('from_post', from_post)
  left_sibling = pViewLocal.prev()
  if left_sibling.html() != undefined
    left_sibling.remove() if left_sibling.data('from_post') == from_post
  setTimeout ->
    get_post(pNum, pViewLocal)
  , 500
  return false

get_post = (id, element) ->
  id = parseInt(id)
  post = $("#i#{id}")
  show_post = (parent, object) ->
    object.css("opacity", 0)
    parent.html('')
    parent.append(object)
    if object.hasClass('thread') or object.find('.thread').first().html() != undefined
      object.find('.thread_header').remove()
      object.find('.omitted').remove()
      object.find('.fav_button').remove()
      object.find('.hide_button').remove()
    else
      object.find('.context_link').remove()
      object.find('.manage_container').remove()
      object.removeClass('highlighted')
    rebind()
    object.animate({opacity: 1}, 400)
    return false
  if post.html() != undefined
    data = post.find('blockquote').first().data('initial_text')
    post = post.clone()
    post.find('blockquote').first().data('initial_text', data)
    show_post(element, post)
  else
    $.ajax
      url: '/get_post'
      type: 'post'
      async: true
      data: {rid: id}
      success: (response) ->
        if response == '0'
          show_post(element, $('<p>Пост не найден</p>'))
        else
          post = $(response)
          if post.hasClass('post_container')
            post = post.find('.post').first()
          else if post.hasClass('thread_container')
            post = post.find('.thread').first()
          show_post(element, post)
        return false
      error: (response) ->
        show_post(element, $("<p>Ошибка</p>"))
        return false
  return false

sosnooley = ->
  return false

show_dropdown = ->
  mouse_over_element = $(this)
  if $(this).attr('id') == 'tags'
    element = $('#taglist')
  else
    element = $('#posting_counters_dropdown')
  element.animate({top: 0}, 300)
  return false

hide_dropdown = ->
  mouse_over_element = null
  if $(this).attr('id') == 'tags' or $(this).attr('id') == 'taglist'
    element = $('#taglist')
  else
    element = $('#posting_counters_dropdown')
  setTimeout ->
    if mouse_over_element == null
      element.animate({top: -(element.height() + 50)}, 300)
  , 150
  return false

show_picture_original = ->
  picture = $(this).find('img')
  picture.removeAttr('width').removeAttr('height')
  needed = picture.attr('original')
  if needed == undefined
    needed = picture.parent().attr('href') 
  current = picture.attr('src')
  loading = $(this).find('.pic_loading')
  loading.css('opacity', '0.7')
  picture.attr('src', needed)
  picture.attr('original', current)
  picture.load ->
    loading.css('opacity', 0)
  return false

highlight_post = (id) ->
  post = $("#i#{id}")
  if post.hasClass('post')
    post.addClass('highlighted')
    if highlighted_post != null
      highlighted_post.removeClass('highlighted')
    highlighted_post = post
  return false

show_delete_button = ->
  $(this).find('.manage_button').css('opacity', '1')
  return false

hide_delete_button = ->
  $(this).find('.manage_button').css('opacity', '0')
  return false


update_references = (object) ->
  $.each object.find('blockquote .post_link'), (index, div) ->
    div = $(div)
    post_id = div.find('a').attr('href').split('#')
    post_id = post_id[post_id.length-1]
    post = $("##{post_id}")
    if post.html() != undefined
      this_id = div.parent().parent()
      if this_id.hasClass('post_body')
        this_thread_id = "i#{this_id.parent().attr('thread')}"
        this_id = this_id.parent().attr('id')
      else
        this_id = this_id.attr('id')
        this_thread_id = this_id
      rids = post.find('.replies_rids')
      href = "/#{this_thread_id.substring(1)}.html##{this_id}"
      content = "&gt;&gt;#{this_id.substring(1)}"
      link = "<div class='post_link'><a href='#{href}'>#{content}</a></div>"
      if (rids.html() != undefined)
        rids.append(' ' + link) if (rids.html().search(content) == -1)
      else
        post.find('blockquote').after("<div class='replies_rids'>Ответы: #{link}")
  return false

refresh_captcha = (image, focus=true) ->
  $.ajax
    url: '/captcha_refresh'
    type: 'post'
    success: (response) ->
      $('.captcha_field img').attr('src', "/captcha_gen?key=#{response}")
      image.load ->
        input = image.parent().find('.captcha_word')
        input.val('')
        input.focus() if focus
        image.unbind().click ->
          refresh_captcha($(this))
      return false
    error: (response) -> 
      window.location.reload()
  return false

blur_form = (form) ->
  $('form').unbind()
  $('form').find('.form_submit').attr('disabled', 'disabled')
  $('form').find('.errors').html('')
  qr_form.find('input').blur()
  qr_form.find('textarea').blur()
  form.animate({opacity: 0.6}, 400)
  return false

unblur_form = (form) ->
  rebind()
  $('form').find('.form_submit').removeAttr('disabled')
  form.animate({opacity: 0.9}, 400)
  return false

clear_form = (form) ->
  form.find('textarea').val('')
  form.find('.form_title').val('')
  form.find('.video_field').val('')
  file = form.find('.file_field')
  file.parent().html(file.parent().html())
  return false

hide = ->
  button = $(this)
  container = parents_until(button, ['post_container', 'thread_container'])
  container.css('opacity', 0.5)
  $.ajax
    type: 'post'
    url: button.attr('href')
    data: {'ajax': 'enabled'}
    success: (response) ->
      container.replaceWith($(response))
      rebind()
      return false
    error: (response) ->
      alert(response.responseText)
      return false
  return false

refresh_thread = ->
  return false if need_to_update == false
  need_to_update = false
  clicked = ($(this).html() != undefined)
  button = $('#refresh_button')
  url = button.attr('href')
  button.addClass('disabled')
  button.data('initial_text', button.html())
  button.html('обновляем...')
  timestamp = $('.post').last().attr('timestamp')
  $.ajax
    url: url
    async: true
    data: {'timestamp': timestamp}
    type: 'post'
    success: (response) ->
      if response != '0'
        response = $(response)
        n = response.find('.post').size()
        $('#thread_container').append(response)
        refresh_thread.done = true
        update_references(response)
        rebind()
        submit_form_callback() if post_to_update != null
        button.html('новые: +' + n) if post_to_update == null
        increase_replies_count(n)
      else
        button.html('нет новых') 
      sosnooley = ->
        need_to_update = true
        button.removeClass('disabled')
        button.html(button.data('initial_text'))
      setTimeout(sosnooley, 3000) if post_to_update == null
      return false
    error: (response) ->
      return false
  return false

bold = ->
  wakaba_mark($(this), '**', '**')

italic = ->
  wakaba_mark($(this), '*', '*')

underline = ->
  wakaba_mark($(this), '__', '__')

spoiler = ->
  wakaba_mark($(this), '%%', '%%')

quote = ->
  wakaba_mark($(this), '> ', '')

strike = ->
  wakaba_mark($(this), '_', '_')

link = ->
  href = prompt("Введите адрес ссылки:")
  text = prompt("Введите название:")
  result = "[#{href} || #{text}]"
  wakaba_mark($(this), result, '')

wakaba_mark = (object, start, end) ->
  textarea = object.parent().parent().parent().find('textarea')
  initial_value = textarea.val()
  section = textarea.getSelectionText()
  left = initial_value.substring(0, section.start)
  right = initial_value.substring(section.end, initial_value.length)
  section.text = section.text.replace(/\n/mg, "#{end}\n#{start}")
  textarea.val(left + start + section.text + end + right)
  caret = section.end + start.length
  textarea.focus().caret(caret, caret)    
  return false


expand_thread = ->
  button = $(this)
  button.data('initial_value', button.html())
  button.html('подождите...').attr('style', 'text-decoration:none;color:black')
  container = parents_until(button, ['thread_container'])
  button.data('posts', container.find('.post_container'))
  $.ajax
    url: button.attr('href')
    type: 'post'
    success: (response) ->
      if response != '0'
        button.html('свернуть тред').removeAttr('style')
        button.unbind().click(shrink_thread)
        response = $(response)
        container.find('.post_container').remove()
        container.append(response)
        strip_text()
        rebind()
      else
        button.html('да ты охуел')
      return false
    error: (response) ->
      alert('Произошла ошибка.')
  return false


shrink_thread = ->
  button = $(this)
  container = parents_until(button, ['thread_container'])
  container.find('.post_container').remove()
  container.append(button.data('posts'))
  button.html(button.data('initial_value'))
  rebind()
  return false

go_up = ->
  $.scrollTo('0%', 300)
  return false

go_down = ->
  $.scrollTo('100%', 300)
  return false

check_up_button = ->
  elem = $("#full_form_button")
  top = $(window).scrollTop()
  bottom = top + $(window).height()
  elem_top = elem.offset().top
  elem_bottom = elem_top + elem.height()
  if (elem_bottom <= bottom) and (elem_top >= top)
    $('#up_button').addClass('disabled')
  else
    $('#up_button').removeClass('disabled')
  elem = $("footer").first()
  top = $(window).scrollTop()
  bottom = top + $(window).height()
  elem_top = elem.offset().top
  elem_bottom = elem_top + elem.height()
  if (elem_bottom <= bottom) and (elem_top >= top)
    $('#down_button').addClass('disabled')
  else
    $('#down_button').removeClass('disabled')
  return false


show_video = ->
  $(this).parent().find('.file_info').remove()
  video_id = $(this).attr('id')
  video = '<object width="320" height="240" class="video">
            <param name="movie"
              value="https://www.youtube.com/v/' + video_id + '?version=3&autoplay=1">
            </param>
            <param name="allowScriptAccess" value="always"></param>
            <embed src="https://www.youtube.com/v/' + video_id + '?version=3&autoplay=1"
            type="application/x-shockwave-flash"
         allowscriptaccess="always"
         width="320" height="240"></embed>
        </object>'
  $(this).replaceWith($(video))
  return false


close_popup = ->
  popup.css('display', 'none')
  document.cookie = "popup_closed=true; path=/; expires=session"
  return false

expand_text = ->
  blockquote = $(this)
  while true
    blockquote = blockquote.parent()
    break if blockquote.is('blockquote')    
  text = blockquote.data('initial_text')
  blockquote.html(text)
  blockquote.data('clicked', true)
  rebind()
  return false

strip_text = (element=null) ->
  if controller == 'threads' and (action == 'index' or action == 'page')
    $.each $('blockquote'), (index, blockquote) ->
      blockquote = $(blockquote)
      if blockquote.html().length > 1800
        blockquote.data('initial_text', blockquote.html())
        stripped_text = blockquote.html().substring(0,1800) + '...  '
        stripped_text += "<a class='fake_link expand_text_button'>Далее</a>"
        blockquote.html(stripped_text)

refresh_live = ->
  return false if live_processing == true
  live_processing = true
  last_rid = $('#live_container .container').first()
  last_rid = last_rid.attr('rid')
  $.ajax 
    url: "/live/"
    data: {rid: last_rid}
    type: 'post'
    success: (response) ->
      content = $(response)
      content.css('opacity', '0')
      $('#live_container .container').first().before(content)
      live_processing = false
      update_references(content)
      rebind()
      content.animate({opacity: 1}, 1500)
      count = $('#live_container .container').size()
      if count > 15
        increase_replies_count(count - 15)
        $.each $('#live_container .container'), (index, div) ->
          if index > 14
            $(div).remove()
        return false
      return false
    error: ->
      live_processing = false
      window.location.reload()
  return false


increase_replies_count = (plus) ->
  span = $("#posting_info span").first()
  count = parseInt(span.html())
  plus = parseInt(plus)
  count += plus
  span.html(count)
  return false

show_file_info = ->
  $(this).find('.file_info').css('opacity', 0.9)
  return false

hide_file_info = ->
  $(this).find('.file_info').css('opacity', 0)
  return false

parents_until = (object, variants) ->
  procceed = true
  result = object
  while procceed == true
    procceed = false if result.is('section')
    result = result.parent()
    for cls in variants
      procceed = false if result.hasClass(cls)
  return result

toggle_fav = ->
  link = $(this)
  src = link.find('img').attr('src')
  $.ajax 
    url: link.attr('href')
    type: 'post'
    success: (response) ->
      if response == 'success'
        if link.data('on') == false
          link.find('img').attr('src', '/star_gold.png')
          link.attr('title', 'Убрать из избранного')
          link.data('on', true)
        else
          link.find('img').attr('src', '/star_black.png')
          link.attr('title', 'Добавить в избранное')
          link.data('on', false)
      else
        alert('В избранном можно хранить до 15 тредов.')
      return false
    error: () ->
      alert('Произошла ошибка.')
      return false
  return false


show_manage_menu = ->
  mouse_over_element = null
  menu = $(this).parent().find('.manage_menu')
  menu.css({display: 'table', opacity: 0})
  menu.animate({opacity: 0.9}, 250)
  return false

hide_manage_menu = ->
  mouse_over_element = null
  setTimeout ->
    if mouse_over_element == null
      $('.manage_menu').animate({opacity: 0}, 250)
      setTimeout ->
        $('.manage_menu').css('display', 'none')
      , 260
  , 300
  return false

mouse_over = ->
  mouse_over_element = $(this)
  return false

delete_post = ->
  if confirm('Точно удалить?')
    link = $(this)
    f = 'off'
    f = 'on' if link.hasClass('delete_file_button')
    $('.manage_menu').css('opacity', 0)
    post = parents_until(link, ['post', 'thread'])
    post.parent().css('opacity', 0.5)
    $.ajax
      url: link.attr('href')
      type: 'post'
      data: {'ajax': 'enabled', 'file_only': f}
      success: (response) ->
        if response == 'success'
          if f == 'on'
            post.find('.file_container').remove()
            post.find('.delete_file_button').remove()
            post.parent().css('opacity', 1)
          else
            if action == 'show' and post.hasClass('thread ')
              document.location = '/~/'
            else
              post.parent().remove()
        else
          alert(response)
          post.parent().css('opacity', 1)
        return false
      error: (response) ->
        alert('Произошла ошибка.')
        return false
  return false


edit_post = ->
  link = $(this)
  post = parents_until(link, ['post', 'thread'])
  blockquote = post.find('blockquote')
  textarea = $("<textarea></textarea>")
  textarea.css('width', blockquote.width() + 'px')
  textarea.css('height', blockquote.height() + 'px')
  post.css('opacity', 0.5)
  if link.hasClass('edit_button')
    $.ajax
      type: 'get'
      url: link.attr('href')
      success: (response) ->
        post.css('opacity', 1)
        blockquote.before(textarea)
        blockquote.css('display', 'none')
        textarea.focus()
        textarea.html(response)
        link = $("<br /><a href='#{link.attr('href')}' class='save_edit_button'>сохранить</a>")
        textarea.after(link)
        link.click(edit_post)
        return false
      error: ->
        alert('Произошла ошибка.')
        return false
  else
    $.ajax
      type: 'post'
      url: link.attr('href')
      data: {'message': post.find('textarea').val()}
      success: (response) ->
        post.css('opacity', 1)      
        post.find('textarea').remove()
        post.find('br').remove()
        link.remove()
        blockquote.html(response)
        update_references(post)
        blockquote.css('display', 'block')
        rebind()
        return false
      error: ->
        alert('Произошла ошибка.')
        return false
  return false