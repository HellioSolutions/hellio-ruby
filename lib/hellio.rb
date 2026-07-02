# frozen_string_literal: true

require "hellio/version"
require "hellio/errors"
require "hellio/http"
require "hellio/client"

# Official Ruby SDK for the Hellio Messaging API v1.
#
# Quick start:
#
#   client = Hellio::Client.new(token: "your-token")
#   client.sms("233241234567", "Hello!")
#
module Hellio
end
