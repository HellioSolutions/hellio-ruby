# frozen_string_literal: true

module Hellio
  # Base error for every failure returned by the Hellio Messaging API.
  # Carries the HTTP status code and the parsed response body so callers can
  # inspect the details (for 422, read #errors for field-level messages).
  class Error < StandardError
    attr_reader :status_code, :response

    def initialize(message = nil, status_code: nil, response: nil)
      super(message)
      @status_code = status_code
      @response = response
    end

    # Field-level validation details, present on 422 responses.
    def errors
      return nil unless response.is_a?(Hash)

      response["errors"]
    end
  end

  # 401: the API token is missing, malformed, or revoked.
  class InvalidApiTokenError < Error; end

  # 402: the account balance is too low to complete the request.
  class InsufficientBalanceError < Error; end

  # 422: the request failed validation. See #errors for the details.
  class ValidationError < Error; end

  # 429: too many requests. The limit is 120 requests per minute per token.
  class RateLimitError < Error; end
end
