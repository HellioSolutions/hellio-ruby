# Hellio Messaging - Official Ruby SDK

[![tests](https://github.com/HellioSolutions/hellio-ruby/actions/workflows/tests.yml/badge.svg)](https://github.com/HellioSolutions/hellio-ruby/actions/workflows/tests.yml)
[![Gem Version](https://img.shields.io/gem/v/hellio-messaging.svg)](https://rubygems.org/gems/hellio-messaging)
[![Gem Downloads](https://img.shields.io/gem/dt/hellio-messaging.svg)](https://rubygems.org/gems/hellio-messaging)
[![License](https://img.shields.io/github/license/HellioSolutions/hellio-ruby.svg)](LICENSE)

Ruby client for the [Hellio Messaging](https://helliomessaging.com) API v1:
**SMS**, **OTP** (SMS / email / voice), **Voice broadcasts**, **Number Lookup (HLR)**,
**Email Verification**, **USSD**, **Pricing**, **Balance**, and **Webhooks**. It
uses only the Ruby standard library (`net/http` and `json`), so there are no
runtime dependencies.

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

## USSD

USSD endpoints live under `client.ussd`. Build an app whose `callback_url`
Hellio calls on each session step, simulate the flow while still in test mode,
rent an extension (the short code subscribers dial), then switch the app to
live.

Apps have two modes, `"test"` and `"live"`. A new app starts in `"test"` and
carries both a `test_secret` (prefix `ussk_test_`) and a `live_secret` (prefix
`ussk_live_`); `mode`/`is_live` say which one is active. App and extension ids
are UUID strings.

```ruby
# Pricing and availability
client.ussd.pricing                 # short code, session prices, extension prices
client.ussd.availability("100")     # {"data" => {"code" => "100", "valid" => true, "available" => true, "monthly_price" => "50.00"}}

# Apps - Hellio POSTs each session step to callback_url. New apps start in test mode.
app = client.ussd.create_app(name: "Airtime", callback_url: "https://your-app.com/ussd")
app_id = app["data"]["id"]          # UUID string
app["data"]["mode"]                 # "test"
app["data"]["test_secret"]          # "ussk_test_..."
client.ussd.apps
client.ussd.update_app(app_id, active: false)

# Rotate a secret for one mode (test or live)
client.ussd.rotate_secret(app_id, "test")

# Simulate a session - always sandboxed (no charge, no extension).
# new_session: true on the first step, then reuse the same session_id.
# service_code is optional and defaults to the shared short code.
client.ussd.simulate(app_id: app_id, session_id: "sess-1",
                     msisdn: "233241234567", new_session: true)
client.ussd.simulate(app_id: app_id, session_id: "sess-1",
                     msisdn: "233241234567", input: "1")

# Extensions - the code subscribers dial, paid from the dedicated USSD balance
client.ussd.extensions
ext = client.ussd.rent_extension("100", app_id: app_id)

# Go live once an extension is purchased
client.ussd.set_mode(app_id, "live")

# Sessions
client.ussd.sessions(status: "ended")
client.ussd.session("6f1c...")      # UUID string

client.ussd.release_extension(ext["data"]["id"])
client.ussd.delete_app(app_id)
```

Renting an extension that is no longer available raises `Hellio::ConflictError`
(409); an underfunded USSD balance raises `Hellio::InsufficientBalanceError`
(402, slug `insufficient_ussd_balance`). The USSD balance is dedicated, separate
from SMS credit and the main wallet. Switching an app to live before an
extension is purchased raises `Hellio::ExtensionRequiredError` (402, slug
`extension_required`).

### Handling the inbound callback

When a subscriber uses your extension, Hellio POSTs a JSON body
(`sessionId`, `msisdn`, `serviceCode`, `input`, `sequence`, `mode`) to your
app's `callback_url`, signed with an `X-Hellio-Signature` header set to
`HMAC-SHA256(rawBody, secret)` where `secret` is the app's secret for the mode
that raised the call (`test_secret` in test mode, `live_secret` in live mode).
Verify it, then reply with `message` and `action` (`"continue"` or `"end"`).

```ruby
require "openssl"
require "json"

post "/ussd" do
  raw = request.body.read
  expected = OpenSSL::HMAC.hexdigest("SHA256", ENV["USSD_APP_SECRET"], raw)
  halt 401 unless Rack::Utils.secure_compare(expected, request.env["HTTP_X_HELLIO_SIGNATURE"].to_s)

  payload = JSON.parse(raw)
  content_type :json
  { message: "Welcome to #{payload['serviceCode']}", action: "continue" }.to_json
end
```

## Error handling

Non-2xx responses raise typed errors (all subclass `Hellio::Error`). Each error
carries `status_code` and the parsed `response` body; `ValidationError` also
exposes field-level details through `#errors`.

| Error | Status |
|---|---|
| `Hellio::InvalidApiTokenError` | 401 |
| `Hellio::InsufficientBalanceError` | 402 |
| `Hellio::ExtensionRequiredError` | 402 (slug `extension_required`) |
| `Hellio::ConflictError` | 409 |
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
