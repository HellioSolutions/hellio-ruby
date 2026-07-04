# frozen_string_literal: true

require "json"
require "uri"

require "hellio/errors"
require "hellio/http"

module Hellio
  # Hellio Messaging API v1 client. Authenticates with a Bearer token and exposes
  # one method per endpoint. Every call returns the decoded JSON as a Hash with
  # string keys (payloads are under "data"); non-2xx responses raise a typed
  # Hellio::Error subclass.
  class Client
    DEFAULT_BASE_URL = "https://api.helliomessaging.com/v1"
    DEFAULT_TIMEOUT = 30

    attr_reader :base_url, :timeout, :default_sender

    # token          - API token (falls back to HELLIO_API_TOKEN).
    # base_url       - API base URL (falls back to HELLIO_BASE_URL, then default).
    # timeout        - request timeout in seconds (default 30).
    # default_sender - Sender ID used by #sms (falls back to HELLIO_DEFAULT_SENDER).
    # http           - HTTP adapter; inject a fake in tests. Defaults to net/http.
    def initialize(token: nil, base_url: nil, timeout: nil, default_sender: nil, http: nil)
      @token = token || ENV["HELLIO_API_TOKEN"]
      @base_url = (base_url || ENV["HELLIO_BASE_URL"] || DEFAULT_BASE_URL).sub(%r{/+\z}, "")
      @timeout = timeout || DEFAULT_TIMEOUT
      @default_sender = default_sender || ENV["HELLIO_DEFAULT_SENDER"]
      @http = http || NetHttpAdapter.new
    end

    # ---------------------------------------------------------------- Account

    # Current account balance and available credit.
    def balance
      get("balance")
    end

    # Per-network SMS pricing. Pass an ISO-2 country code to narrow by country.
    def pricing(country = nil)
      get("pricing", country.nil? ? {} : { "country" => country })
    end

    # -------------------------------------------------------------------- SMS

    # Send an SMS. recipients may be a single string, a comma-separated string,
    # or an array of numbers.
    def sms(recipients, message, sender: nil, gateway: nil)
      post("sms/send", compact(
        "recipients" => to_list(recipients),
        "sender" => sender || default_sender,
        "message" => message,
        "gateway" => gateway
      ))
    end

    # Delivery status for a single message.
    def message(id)
      get("messages/#{id}")
    end

    # Summary for a single campaign.
    def campaign(id)
      get("campaigns/#{id}")
    end

    # -------------------------------------------------------------------- OTP

    # Send a one-time passcode. `to` is a phone number (sms/voice/whatsapp) or an
    # email (email). `sender` (Sender ID) is required for sms/voice and must be
    # approved on your account; it is ignored for whatsapp and email. Optional
    # `length` (4-10 digits) and `expiry` (validity in minutes).
    def otp(to, sender: nil, channel: "sms", purpose: nil, length: nil, expiry: nil, gateway: nil)
      destination_key = (channel == "email" ? "email" : "mobile_number")

      post("otp/send", compact(
        "channel" => channel,
        destination_key => to,
        "sender" => sender,
        "purpose" => purpose,
        "length" => length,
        "expiry" => expiry,
        "gateway" => gateway
      ))
    end

    # Verify a one-time passcode and return the full response.
    def verify_otp(to, code, channel: "sms")
      destination_key = (channel == "email" ? "email" : "mobile_number")

      post("otp/verify", compact(
        "channel" => channel,
        destination_key => to,
        "code" => code
      ))
    end

    # Convenience wrapper: true when the code is valid, false otherwise.
    # A 422 validation failure is treated as "not verified".
    def verify(to, code, channel: "sms")
      result = verify_otp(to, code, channel: channel)
      truthy?(result.is_a?(Hash) ? result.dig("data", "verified") : nil)
    rescue ValidationError
      false
    end

    # ------------------------------------------------------------------ Voice

    # Voice broadcast. Provide `text` (read with TTS) OR `audio_url` (fetched
    # and played). recipients accepts the same shapes as #sms.
    def voice(recipients, caller_id, text: nil, audio_url: nil, name: nil)
      post("voice/send", compact(
        "recipients" => to_list(recipients),
        "caller_id" => caller_id,
        "text" => text,
        "audio_url" => audio_url,
        "name" => name
      ))
    end

    # Status for a single voice broadcast.
    def voice_status(id)
      get("voice/#{id}")
    end

    # ----------------------------------------------------------- Number lookup

    # Submit numbers for HLR lookup. numbers accepts a string, comma list, or array.
    def lookup(numbers)
      post("lookup", "numbers" => to_list(numbers))
    end

    # List previously submitted lookups.
    def lookups
      get("lookups")
    end

    # Result for a single lookup.
    def lookup_result(id)
      get("lookup/#{id}")
    end

    # ------------------------------------------------------- Email verification

    # Verify one or more email addresses. emails accepts a string, comma list, or array.
    def verify_email(emails)
      post("email/verify", "emails" => to_list(emails))
    end

    # --------------------------------------------------------------- Webhooks

    # List registered webhooks.
    def webhooks
      get("webhooks")
    end

    # Register a webhook. Pass `events` to subscribe to specific event types.
    def create_webhook(url, events: [])
      post("webhooks", compact(
        "url" => url,
        "events" => (events.nil? || events.empty? ? nil : events)
      ))
    end

    # Delete a webhook by id.
    def delete_webhook(id)
      delete("webhooks/#{id}")
    end

    # --------------------------------------------------------------- internals

    private

    def get(path, query = {})
      request(:get, path, query: query)
    end

    def post(path, body = {})
      request(:post, path, body: body)
    end

    def delete(path)
      request(:delete, path)
    end

    def request(method, path, query: {}, body: nil)
      response = @http.call(
        method: method,
        url: build_url(path, query),
        headers: headers,
        body: body.nil? ? nil : JSON.generate(body),
        timeout: timeout
      )

      data = parse(response.body)
      return data if response.status.to_i.between?(200, 299)

      raise error_for(response.status.to_i, data)
    end

    def headers
      {
        "Authorization" => "Bearer #{@token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
    end

    def build_url(path, query)
      url = "#{base_url}/#{path.sub(%r{\A/+}, "")}"
      return url if query.nil? || query.empty?

      "#{url}?#{URI.encode_www_form(query)}"
    end

    def parse(body)
      return {} if body.nil? || body.to_s.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      {}
    end

    def error_for(status, data)
      message =
        if data.is_a?(Hash) && data["message"].is_a?(String)
          data["message"]
        else
          "Hellio API request failed."
        end

      error_class =
        case status
        when 401 then InvalidApiTokenError
        when 402 then InsufficientBalanceError
        when 422 then ValidationError
        when 429 then RateLimitError
        when 503 then ServiceUnavailableError
        else Error
        end

      error_class.new(message, status_code: status, response: data)
    end

    # Normalize a recipient/number/email input into an array of strings.
    def to_list(value)
      return value.map(&:to_s) if value.is_a?(Array)

      value.to_s.split(",").map(&:strip).reject(&:empty?)
    end

    # Drop keys whose value is nil so they are omitted from the request body.
    def compact(hash)
      hash.reject { |_, v| v.nil? }
    end

    def truthy?(value)
      return false if value.nil? || value == false
      return false if value == 0
      return false if value.is_a?(String) && (value.empty? || value == "0")

      true
    end
  end
end
