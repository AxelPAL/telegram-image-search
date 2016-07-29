require_relative 'config/config.rb'
require_relative 'config/environment'
require 'json'
require 'telegram_bot'
require 'telegram/bot'
require 'net/http'
require 'open-uri'
require 'htmlentities'
require 'nokogiri'
require_relative 'models/user'

if Gem.win_platform?
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

class String
  def contains_cyrillic?
    !!(self =~ /\p{Cyrillic}/)
  end
end

Telegram::Bot::Client.run(@telegram_api) do |bot|
  bot.listen do |message|
    user = User.find_by_nickname(message.chat[:username])
    if user.nil?
      user = User.new
      user.nickname = message.chat[:username]
      user.name = message.chat[:first_name]
      user.surname = message.chat[:last_name]
      user.language = 'eng'
      user.save!
    end
    begin
      case message.text
        when '/start'
        when '/help'
        when 'start'
          object = {
              keyboard: [
                  ['English'],
                  ['Русский']
              ],
              one_time_keyboard: true
          }
          bot.api.send_message(chat_id: message.chat.id, text: 'Please, choose your language.', reply_markup: JSON.generate(object))
        when 'English'
          user.language = 'eng'
          user.save!
          bot.api.send_message(chat_id: message.chat.id, text: 'Hello. This bot will allow you to search objects by the image. Just send the photo and the bot will return some links to you related to this object')
        when 'Русский'
          user.language = 'rus'
          user.save!
          bot.api.send_message(chat_id: message.chat.id, text: 'Здравствуйте. Этот Бот позволит вам искать объекты по изображению. Просто отправьте любое изображение (или фотографию) и Бот вернет вам несколько ссылок с тем, что будет на фотографии');
        else
          if message.photo.length > 0
            file_id = message.photo.last[:file_id]
            file_info = bot.api.get_file(file_id: file_id)
            file_path = file_info['result']['file_path']
            file_url = "https://api.telegram.org/file/bot#{@telegram_api}/#{file_path}"

            if file_url
              if user.language == 'rus'
                domain = 'yandex.ru'
              else
                domain = 'yandex.com'
              end

              page = Nokogiri::HTML(open("https://#{domain}/images/search?img_url=#{HTMLEntities.new.encode file_url}&rpt=imageview"))
              links = page.css('a.link.link_theme_normal.other-sites__title-link.i-bem')
              the_links = []
              if links.length > 0
                links.each do |link|
                  name = link.text
                  link_href = link['href']
                  if (user.language == 'eng' && !(name.contains_cyrillic?)) || user.language == 'rus'
                    the_link = "<a href='#{link_href}'>#{name}</a>"
                    the_links.push(the_link)
                  end
                  break if the_links.length > 9
                end
                bot.api.send_message(chat_id: message.chat.id, text: the_links.join("\n\n"), :parse_mode => 'html')
              end
            end
          else
            if user.language == 'rus'
              bot.api.send_message(chat_id: message.chat.id, text: 'Вы должны отправить изображение, чтобы получить ответ от Бота.')
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'You should upload the photo to get answer from the bot.')
            end
          end
      end
    rescue Telegram::Bot::Exceptions::ResponseError => detail
      print detail.backtrace.join("\n")
    end
  end
end
