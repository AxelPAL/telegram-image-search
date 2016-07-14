require_relative 'config'
require 'telegram_bot'
require 'telegram/bot'
require 'net/http'
require 'open-uri'
require 'htmlentities'
require 'nokogiri'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

Telegram::Bot::Client.run(@telegram_api) do |bot|
  bot.listen do |message|
    case message.text
      when '/start'
        bot.api.send_message(chat_id: message.chat.id, text: 'Здравствуйте. Этот Бот позволит вам искать объекты по изображению. Просто отправьте любое изображение (или фотографию) и Бот вернет вам несколько ссылок с тем, что будет на фотографии');
      else
        if message.photo.length > 0
          file_id = message.photo.last[:file_id]
          file_info = bot.api.get_file(file_id: file_id)
          file_path = file_info['result']['file_path']
          file_url = "https://api.telegram.org/file/bot#{@telegram_api}/#{file_path}"

          if file_url
            page = Nokogiri::HTML(open("https://yandex.ru/images/search?img_url=#{HTMLEntities.new.encode file_url}&rpt=imageview"))
            links = page.css('a.link.link_theme_normal.other-sites__title-link.i-bem')
            the_links = []
            if links.length > 0
              links[0..4].each do |link|
                name = link.text
                link_href = link['href']
                # link_href = link.next_element['href']
                the_link = "<a href='#{link_href}'>#{name}</a>"
                the_links.push(the_link)
              end
              bot.api.send_message(chat_id: message.chat.id, text: the_links.join("\n"), :parse_mode => 'html')
            end
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'Вы должны отправить изображение, чтобы получить ответ от Бота.')
        end
    end
  end
end