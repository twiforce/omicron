# -*- coding: utf-8 -*-

module Verbose
  def self.date(date, show_time=true)
    months = [  'января',   'февраля',    'марта',
                'апреля',   'мая',        'июня',
                'июля',     'августа',    'сентября',
                'октября',  'ноября',     'декабря'    ]
    now = Time.now.getlocal
    date = date.getlocal  
    result = ''
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

  def self.replies(number)
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

  def self.replies_new(number)
    result = "#{number} новы"
    number_mod = number % 10
    if number_mod == 1 and (number != 11 and number %100 != 11)
      result += 'й'
    else
      result += 'х'
    end
  end

  def self.messages(number)
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

  def self.threads(number)
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

  def self.days(number)
    number_mod = number % 10
    if number_mod == 1
      "#{number} сутки"
    else
      "#{number} суток"
    end
  end

  def self.files(number)
    result = "#{number} с файл"
    if number == 1
      result + 'ом'
    else
      result + 'ами'
    end
  end

  def self.parse_reverse(text)
    def hui(text, start, ending=start)
      "#{start}#{text}#{ending}"
    end

    text.gsub!(/<b>(.+?)<\/b>/, hui('\1', '**'))
    text.gsub!(/<i>(.+?)<\/i>/, hui('\1', '*'))
    text.gsub!(/<u>(.+?)<\/u>/, hui('\1', '__'))
    text.gsub!(/<span class='quote'>&gt;\W+(.+?)<\/span><br \/>/, hui('\1', '> ', nil))
    text.gsub!(/<span class='spoiler'>(.+?)<\/span>/, hui('\1', '%%'))
    text.gsub!(/<div class='post_link'>.*&gt;&gt;(.+?).*<\/div>/, hui('\1', '>>', nil))
    text.gsub!('&amp;', '&')
    text.gsub!('&lt;', '<')
    text.gsub!('&gt;', '>')
    text.gsub!('<br />', "\n")
    logger.info text.inspect
    return text
  end


  def self.deleted_single(rids, reason)
    rids = [rids] unless rids.kind_of?(Array)
    if rids.size > 1
      text = "Удалены сообщения: #{rids.join(', ')} (всего #{rids.size})."
    else
      text = "Удалено сообщение #{rids[0]}."
    end
    text += "<br />Причина: #{reason}."
    return text
  end

  def self.deleted_many(rid, minutes, reason)
    text = "Все сообщения автора ##{rid} за последние #{minutes} минут удалены."
    text += "<br />Причина: #{reason}."
    return text
  end

  def self.banned(rids, days, reason)
    rids = [rids] unless rids.kind_of?(Array)
    if rids.size > 1
      text = "Забанены авторы сообщений: #{rids.join(', ')} (всего #{rids.size}). Баны"
    else
      text = "Забанен автор сообщения #{rids[0]}. Бан"
    end
    text += " на #{Verbose::days(days)} (до #{Verbose::date((Time.now + days.days), false)})."
    text += "<br />Причина: #{reason}."
    return text
  end
end
