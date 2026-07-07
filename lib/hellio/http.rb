# frozen_string_literal: true

require "net/http"
require "uri"

module Hellio
  # A minimal HTTP response value object returned by an adapter.
  Response = Struct.new(:status, :body)

  # Default HTTP adapter built on the standard library `net/http`. Tests (or
  # advanced users) can inject any object that responds to #call with the same
  # keyword arguments and returns an object exposing #status and #body.
  class NetHttpAdapter
    def call(method:, url:, headers:, body:, timeout:)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = timeout
      http.read_timeout = timeout

      request_class =
        case method
        when :get then Net::HTTP::Get
        when :post then Net::HTTP::Post
        when :put then Net::HTTP::Put
        when :delete then Net::HTTP::Delete
        else raise ArgumentError, "Unsupported HTTP method: #{method}"
        end

      request = request_class.new(uri.request_uri)
      headers.each { |key, value| request[key] = value }
      request.body = body unless body.nil?

      response = http.request(request)
      Response.new(response.code.to_i, response.body.to_s)
    end
  end
end
