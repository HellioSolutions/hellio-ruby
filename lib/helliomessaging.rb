require "helliomessaging/version"
require "rubygems"
require "net/https"
require "uri"
require "json"

module HellioMessaging
  class HellioMessaging
    def self.send(message, mobile_number)
      client_id                = ENV['HELLIO_MESSAGING_CIENT_ID']
      application_secret       = ENV['HELLIO_MESSAGING_APPLICATION_SECRET']
      sender_id                = ENV['HELLIO_MESSAGING_sender_id_ID']

      raise ArgumentError, 'Set your client_id, application_secret, or sender_id for helliomessaging' unless client_id && application_secret && sender_id

      requested_url = 'https://api.helliomessaging.com/channels/sms/v3/send/?'
      uri = URI.parse(requested_url)
      http = Net::HTTP.start(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = Net::HTTP.post_form(uri, 'client_id' => client_id, 'application_secret' => application_secret, 'message' => message, 'sender_id' => sender_id, 'mobile_number' => mobile_number)
      response = JSON.parse(res.body)
      puts (response)
    end
  end

end
