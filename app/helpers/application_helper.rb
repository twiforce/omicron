# -*- coding: utf-8 -*-

module ApplicationHelper
  def verbose_date(date, show_time=true)
    months = [  'января',   'февраля',    'марта',
                'апреля',   'мая',        'июня',
                'июля',     'августа',    'сентября',
                'октября',  'ноября',     'декабря'    ]
    now = Time.now.getlocal
    date = date.getlocal  
    if now.day == date.day
      result = 'сегодня ' if [now.month, now.year] == [date.month, date.year]
    elsif date.day == (now.day - 1)
      result = 'вчера ' if [now.month, now.year] == [date.month, date.year]
    else
      result = "#{date.day} #{months[date.month - 1]} #{date.year} г."
    end
    result += ' в ' + date.strftime('%H:%M:%S') if show_time
    return result
  end

  def verbose_replies(number)
    return "нет постов" if number == 0
    result = "#{number} пост"
    number_mod = number % 10
    if (2..4).include?(number_mod) and not (12..14).include?(number % 100)
      result + 'а' 
    elsif number_mod != 1 or number == 11
      result + 'ов'
    else
      result
    end
  end

  def verbose_messages(number)
    result = "#{number} сообщени"
    number_mod = number % 10
    if (2..4).include?(number_mod) and not (12..14).include?(number % 100)
      result + 'я' 
    elsif number_mod != 1 or (number == 11 or (number % 100) == 11)
      result + 'ий'
    else
      result + 'е'
    end
  end

  def verbose_threads(number)
    result = "#{number} тред"
    number_mod = number % 10
    if (2..4).include?(number_mod) and not (12..14).include?(number % 100)
      result + 'а' 
    elsif number_mod != 1 or number == 11
      result + 'ов'
    else
      result
    end
  end

  def verbose_days(number)
    number_mod = number % 10
    if number_mod == 1
      "#{number} сутки"
    else
      "#{number} суток"
    end
  end

  def verbose_files(number)
    result = "#{number} с файл"
    if number == 1
      result + 'ом'
    else
      result + 'ами'
    end
  end

  def parse_reverse(text)
    def hui(t, start, ending=start)
      "#{start}#{t}#{ending}"
    end

    text.gsub!(/<b>(.+?)<\/b>/, hui('\1', '**'))
    text.gsub!(/<i>(.+?)<\/i>/, hui('\1', '*'))
    text.gsub!(/<u>(.+?)<\/u>/, hui('\1', '__'))
    text.gsub!(/<s>(.+?)<\/s>/, hui('\1', '_'))
    text.gsub!(/<span class='quote'>(.+?)<\/span><br \/>/, '\1')
    text.gsub!(/<span class='spoiler'>(.+?)<\/span>/, hui('\1', '%%'))
    text.gsub!(/<div class='post_link'>(.*?)&gt;&gt;(.+?)<\/a><\/div>/, hui('\2', '>>', ''))
    text.gsub!('&amp;', '&')
    text.gsub!('&lt;', '<')
    text.gsub!('&gt;', '>')
    text.gsub!('<br />', "\n")
    logger.info text.inspect
    return text
  end


  def verbose_deleted_single(rids, reason)
    "deleted single"
  end

  def verbose_deleted_many(rid, minutes, reason)
    "deleted many"
  end
end
