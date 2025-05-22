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
sender_id = ENV['HELLIO_MESSAGING_SENDER_ID']

time = Time.new
currentDate = time.strftime("%Y%m%d%H")
hashedAuthKey = Digest::SHA1.hexdigest(client_id + application_secret + currentDate)

raise ArgumentError, 'Set your client_id, application_secret, or sender_id for helliomessaging'
unless client_id && application_secret && sender_id

url = 'https://api.helliomessaging.com/v2/sms'
uri = URI.parse(url)

request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
payload = {
    'clientId' => client_id,
    'authKey' => hashedAuthKey,
    'senderId' => sender_id,
    'msisdn' => mobile_number,
    'message' => message
}.to_json
request.body = payload

res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(request)
end

unless res.is_a?(Net::HTTPSuccess)
  error_message = "HTTP Status: #{res.code}"
  begin
    error_body = JSON.parse(res.body)
    error_message += " - Body: #{error_body.inspect}"
  rescue JSON::ParserError
    error_message += " - Body: #{res.body}"
  end
  raise "Hellio API Error: #{error_message}"
end

response = JSON.parse(res.body)
puts(response)
end
end

end
