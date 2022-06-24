require "hellio-ruby/version"
require "rubygems"
require "net/https"
require "uri"
require "json"
require 'digest/sha1'

module HellioMessaging
class SMS
def self.send(message, mobile_number)
client_id = ENV['HELLIO_MESSAGING_CLIENT_ID']
application_secret = ENV['HELLIO_MESSAGING_APPLICATION_SECRET']
sender_id = ENV['HELLIO_MESSAGING_sender_id_ID']

mobile_number = '233242813656'
time = Time.new
currentDate = time.strftime("%Y%m%d")
hashedAuthKey = Digest::SHA1.hexdigest(client_id + application_secret + currentDate)

raise ArgumentError, 'Set your client_id, application_secret, or sender_id for helliomessaging'
unless client_id && application_secret && sender_id

baseUrl = 'https://api.helliomessaging.com/v2/sms?'

uri = URI.parse(baseUrl)
http = Net::HTTP.start(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.request_uri)
res = Net::HTTP.post_form(uri,
    'client_id' => client_id,
    'authKey' => hashedAuthKey,
    'message' => message,
    'sender_id' => sender_id,
    'mobile_number' => mobile_number)
response = JSON.parse(res.body)
puts(response)
end
end

end
