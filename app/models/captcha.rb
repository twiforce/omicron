# -*- coding: utf-8 -*-

class Captcha < ActiveRecord::Base
  before_create do 
    if (captcha = Captcha.where(word: self.word).first)
      captcha.destroy
    end
    if (captcha = Captcha.where(key: self.key).first)
      captcha.destroy
    end    
    logger.info "Generated new captcha #{self.word}/#{self.key}."
  end

  before_destroy do
    logger.info "Captcha #{self.word}/#{self.key} destroyed."
  end

  def self.get_word(cancer=false)
    if cancer
      words = [
        ['ху',      'йня.ета.ец.ёк.ита.ищще.ево.евый.й.якс.йнул'.split('.')],
        ['пост',    'ы.им..ил'.split('.')],
        ['тред',    ['ы', '']],
        ['борд',    'ы.а'.split('.')],
        ['бан',     'ы.ил..им.или'.split('.')],
        ['вин',     'ы.ный.ищще.отА.рар.же'.split('.')],
        ['фейл',    'ил..овый.ишь.ю.им.ед'.split('.')],
        ['анон',    'ы..чик.чики.им.имы.имус.имусы'.split('.')],
        ['сосн',    'у.увшим.ешь.ули.ул.улей.ицкий.и'.split('.')],
        ['двач',    'ер..еры.и.ру.ую.уем.евал.евать'.split('.')],
        ['бамп',    'ы..аю.аем.ну.нул.нем.нут.нутый'.split('.')],
        ['быдл',    'а.о.обыдло.ина.ан.ецо'.split('.')],
        ['говн',    'ы.а.о.ина.ецо.апоешь'.split('.')],
        ['нульч',   'ер..еры.ую.ан'.split('.')],
        ['педал',   'и.ик.ьный.ьчан'.split('.')],
        ['петуш',   'ок.ки.ня.ила'.split('.')],
        ['школ',    'ьник.ьники.ота.отень.яр.яры'.split('.')],
        ['слоу',    'пок..бро.кинг'.split('.')],
        ['ра',      'к.ки.чки.чок.ковый'.split('.')],
        ['суп',     'ец.б'.split('.')],
        ['форс',    'ед..едмем.ил.или.им.ят.ер'.split('.')],
        ['са',      'жа.гАю.жАскрыл.ге.гануть.жица'.split('.')],
        ['вайп',    'ер..алка.ы.ну.нуть.нули.нутый.ают.али.нут'.split('.')],
        ['ло',      'ли.л.лд.ло.ик.лоло'.split('.')],
        ['лигион',  'ер.еры..'.split('.')],
        ['набе',    'г.ги.гаем.жали'.split('.')],
        ['лепр',    'а.оеб'.split('.')],
        ['илит',    'а.ка.ный'.split('.')],
        ['ньюфа',   'г.ги.жек.жина.жный'.split('.')],
        ['олдфа',   'г.ги.жек.жина.жный'.split('.')],
        ['шлю',     'ха.хи.шка.шки.хиненужны'.split('.')],
        ['пизд',    'а.ец.ецовый.атый.ато.уй'.split('.')],
        ['',        'опхуй.десу.ормт.кококо.пошелвон.кинцо.новэй.груша.цэпэ'.split('.')],
        ['',        'безногим.анома.номад.пистон.атятя.зой.викентий.вакаба'.split('.')],
        ['',        'омикрон.фрипорт.мудрец.капча.сейдж.ололо.пахом.параша'.split('.')],
        ['',        'номадница.игортонет.игорнет.ногаемс.ноугеймс.форчан'.split('.')],
        ['',        'бугурт.бомбануло.баттхерт.бутхурт.багет.пека.йоба.схб'.split('.')],
        ['',        'инвайт.вечервхату.сгущенка.пригорело.пукан.пердак.пердачелло'.split('.')],
        ['',        'рулетка.деанон.дионон.кулстори.хлебушек.блогистан.тыхуй'.split('.')],
        ['',        'омск.гитлер.хохлы.анимеговно.двощ.двощер.двощи.петух'.split('.')],
        ['',        'шишка.братишка.поехавший.лишнийствол.удафком.подтирач'.split('.')],
        ['',        'хачи.трубашатал.ненависть.рейдж.алсо.посаны.ролл.сладкийхлеб'.split('.')],
        ['',        'малаца.батя.зделоли.графон.дрейкфейс.короли.джаббер.писечка'.split('.')],
        ['',        'номадница.пативэн.свиборг.корован.трент.фрилансер.кровь.кишки'.split('.')],
        ['',        'всесоснули.сосач.макака.абу.моча.уебывай.съеби.трололо.колчан'.split('.')],
        ['',        %w( пекацефал мыльцо )]
      ]
      word = String.new
      word = words[rand(0..words.length-1)]
      word = word[0] + word[1][rand(0..word[1].length-1)]
    else
      letters1 = ['а', 'е', 'и', 'о', 'у', 'э', 'ю', 'я', 'ё']
      letters2 = 'б.в.г.д.ж.з.й.к.л.м.н.п.р.с.т.ф.х.ц.ч.ш.щ'.split('.')
      letters3 = %w( й ф я ё ч ц ы х ъ ж э ю б щ з )
      word = ''
      while word.length < rand(5..8)
        r = (rand(0..100) > 50)
        word += letters2[rand(0..letters2.length - 1)] if r
        word += letters1[rand(0..letters1.length - 1)] unless r
      end
    end
    return word
  end

  def self.get_key(defence)
    if (record = Captcha.first(order: RANDOM))
      if record.defensive == defence
        logger.info "Trying to get existing one: #{record.word}/#{record.key}..."
        time_passed = Time.now - record.created_at
        if time_passed > 3.minutes and time_passed < 6.minutes
          logger.info "looks okay, using it."
          return record.key
        elsif time_passed > 6.minutes
          logger.info "but it's expired."
          Captcha.where("created_at < ?", (Time.now - 6.minutes)).destroy_all
        else
          logger.info "but it doesn't fit."
        end
      end
    end
    if defence
      word = String.new
      word += Captcha.get_word
      word += Captcha.get_word
      word += Captcha.get_word
      word += Captcha.get_word + "\n"
      word += Captcha.get_word
      word += Captcha.get_word
      word += Captcha.get_word
      word += Captcha.get_word + "\n"
    else
      word = Captcha.get_word(cancer: true)
    end
    key  = rand(89999999)
    return key if Captcha.create(word: word, key: key, defensive: defence)
  end
end