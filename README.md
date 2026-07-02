# Hellio Messaging - Official Ruby SDK

[![tests](https://github.com/HellioSolutions/hellio-ruby/actions/workflows/tests.yml/badge.svg)](https://github.com/HellioSolutions/hellio-ruby/actions/workflows/tests.yml)
[![Gem Version](https://img.shields.io/gem/v/hellio-messaging.svg)](https://rubygems.org/gems/hellio-messaging)
[![Gem Downloads](https://img.shields.io/gem/dt/hellio-messaging.svg)](https://rubygems.org/gems/hellio-messaging)
[![License](https://img.shields.io/github/license/HellioSolutions/hellio-ruby.svg)](LICENSE)

Ruby client for the [Hellio Messaging](https://helliomessaging.com) API v1:
**SMS**, **OTP** (SMS / email / voice), **Voice broadcasts**, **Number Lookup (HLR)**,
**Email Verification**, **Pricing**, **Balance**, and **Webhooks**. It uses only
the Ruby standard library (`net/http` and `json`), so there are no runtime
dependencies.

## Install

```bash
gem install hellio-messaging
```

Or with Bundler, add to your `Gemfile`:

```ruby
gem "hellio-messaging"
```

then run `bundle install`.

## Configure

Generate a token in your dashboard (**Settings -> API -> Generate API token**),
then create a client. You can pass values directly or set environment variables.

```ruby
require "hellio"

client = Hellio::Client.new(
  token: "your-token-here",
  default_sender: "HellioSMS"
)
```

Environment variables are read as fallbacks when an option is omitted:

```dotenv
HELLIO_BASE_URL=https://api.helliomessaging.com/v1
HELLIO_API_TOKEN=your-token-here
HELLIO_DEFAULT_SENDER=HellioSMS
```

```ruby
client = Hellio::Client.new   # reads HELLIO_API_TOKEN, HELLIO_BASE_URL, HELLIO_DEFAULT_SENDER
```

Optional constructor options: `base_url` (defaults to
`https://api.helliomessaging.com/v1`), `timeout` (seconds, default 30), and
`http` (a custom HTTP adapter, mainly for tests).

Every call returns the decoded JSON as a `Hash` with string keys (payloads are
under the `"data"` key). Non-2xx responses raise a typed error (see below).

## Usage

```ruby
# Account
client.balance            # {"data" => {"balance" => "195.0000", "available" => "194.65", ...}}
client.pricing("GH")      # optional ISO-2 country filter

# SMS (recipients: string, comma list, or array)
client.sms("233241234567", "Hello!")
client.sms(["233241234567", "233201234567"], "Hi all", sender: "HellioSMS")
client.message(1024)      # delivery status
client.campaign(1024)     # campaign summary

# OTP - sender (Sender ID) is REQUIRED for sms/voice and must be approved on your account.
# Optional length (4-10 digits) and expiry (minutes). Returns status "queued".
client.otp("233241234567", sender: "HellioSMS")                       # SMS
client.otp("233241234567", sender: "HellioSMS", channel: "voice")     # Voice (TTS reads the code)
client.otp("233241234567", sender: "HellioSMS", length: 6, expiry: 10)
client.otp("user@example.com", channel: "email")                      # Email (no sender)
client.verify("233241234567", "123456")                               # true / false
client.verify_otp("user@example.com", "123456", channel: "email")     # full response

# Voice broadcast - text (we TTS it) or a hosted audio_url
client.voice("233241234567", "HELLIO", text: "Your code is 1 2 3 4")
client.voice(["233241234567"], "HELLIO", audio_url: "https://cdn.example.com/promo.mp3")

# Number lookup (HLR) - async; poll results
client.lookup(["233241234567"])
client.lookups
client.lookup_result(5)

# Email verification
client.verify_email(["user@gmail.com", "bad@nodomain.invalid"])

# Webhooks (receive delivery reports)
client.create_webhook("https://your-app.com/hooks/hellio", events: ["message.delivered", "message.failed"])
client.webhooks
client.delete_webhook(1)
```

Recipient inputs (`sms`, `voice`, `lookup`, `verify_email`) accept a single
string, a comma-separated string, or an array. They are normalized to a list
before the request is sent.

## Error handling

Non-2xx responses raise typed errors (all subclass `Hellio::Error`). Each error
carries `status_code` and the parsed `response` body; `ValidationError` also
exposes field-level details through `#errors`.

| Error | Status |
|---|---|
| `Hellio::InvalidApiTokenError` | 401 |
| `Hellio::InsufficientBalanceError` | 402 |
| `Hellio::ValidationError` (`#errors`) | 422 |
| `Hellio::RateLimitError` | 429 |
| `Hellio::Error` | other |

```ruby
begin
  client.sms("233241234567", "Hi")
rescue Hellio::InsufficientBalanceError => e
  # top up
rescue Hellio::ValidationError => e
  e.errors        # field-level messages
  e.status_code   # 422
  e.response      # full parsed body
end
```

Rate limit: **120 requests/minute** per token.

## Development

```bash
bundle install
bundle exec rake spec
```

Tests use RSpec and WebMock to mock the HTTP layer.

## License

MIT. See [LICENSE](LICENSE).
