# -*- coding: utf-8 -*-

class CaptchaController < ApplicationController
  def generate_image
    if (captcha_record = Captcha.where(key: params[:key].to_i).first)
      captcha_word = captcha_record.word
      rows = captcha_word.scan(/\n/).size
      rows = 1 if rows == 0

      image = Magick::Image.new((captcha_word.length*19+rand(-5..5))/rows, 30*rows) {
        self.background_color = 'transparent'
      }
      iterator    = 0
      offset      = -10
      last_symbol = String.new
      current_row = 1
      while iterator < captcha_word.length
        if captcha_word[iterator] == "\n"
          iterator += 1
          current_row += 1
          offset = -10
          next
        end
        offset    += 15
        offset    += 6 if ['ж', 'щ', 'ш', 'ф', 'м', 'ю'].include?(last_symbol)
        bigs_ones = 'А.Е.И.О.У.Э.Ю.Я.Б.В.Г.Д.Ж.З.Й.К.Л.М.Н.П.Р.С.Т.Ф.Х.Ц.Ч.Ш.Щ'.split('.')
        pointsize = 24 + rand(0..4)
        pointsize = 22 + rand(0..8) if captcha_record.defensive
        letter    = captcha_word[iterator]
        letter    = letter.mb_chars.upcase if rand(9) > 4
        pointsize = 19 + rand(0..5) if bigs_ones.include?(letter)
        random = (rand(0..10) > 5)
        p = 1
        p += 0.7 if captcha_record.defensive
        image.annotate(Magick::Draw.new, 0, 0, offset, -10+30*current_row, letter) {
          self.font_family    = ['Times New Roman', 'Consolas', 'Trebuchet', 'Verdana', 'Georgia', ][rand(0..4)]
          self.fill           = "##{(60 + rand(39)).to_s * 3}"
          self.pointsize      = pointsize
          self.gravity        = Magick::SouthGravity
          self.align          = Magick::LeftAlign
          self.text_antialias = true
          self.rotation       = rand(-20*p..-10*p) if random
          self.rotation       = rand(10*p..20*p) unless random
        }
        last_symbol = captcha_word[iterator]
        iterator += 1
      end
      # image = image.add_noise(Magick::PoissonNoise)
      image.format = 'PNG'
      degree = rand(9..16)
      degree -= degree * 2 if rand(10) > 5
      image = image.swirl(degree) unless captcha_record.defensive
      render(text: image.to_blob, content_type: 'image/png')
    else
      logger.warn 'This captcha doesn\'t exist!'
      render(text: 'huitebe', status: :not_found)
    end
  end

  def refresh_image
    session[:captcha_key] = CaptchaController::get_captcha_key((@enemy or @p.defence_mode))
    return render(text: session[:captcha_key])
  end

  public
  def self.get_captcha_key(defensive_mode)
    logger.info "\nRequesting captcha:"
    return Captcha.get_key(defensive_mode)
  end

  def self.validate(word, key)
    if (captcha = Captcha.where(key: key).first)
      word          = word.to_s.mb_chars.downcase.gsub("\n", '').gsub(' ', '')
      captcha.word  = captcha.word.mb_chars.downcase.gsub("\n", '').gsub(' ', '')
      logger.info "\nValidating captcha, challenge: #{captcha.word}"
      logger.info "Response: #{word}"
      matches = 0
      (0..captcha.word.length-1).each do |iterator|
        matches += 1 if word[iterator] == captcha.word[iterator]
      end
      errors = captcha.word.length - matches
      logger.info "Errors: #{errors}"
      if errors <= 2
        logger.info "Validation passed."
        captcha.destroy
        return true
      else
        logger.info "Validation FAILED!"
        captcha.destroy
      end
    end
    return false
  end
end