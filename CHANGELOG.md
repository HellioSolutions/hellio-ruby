# Changelog

All notable changes to `hellio-messaging` are documented here.
This project follows [Semantic Versioning](https://semver.org).

## [0.1.0] - 2026-07-02

Initial release of the official Ruby SDK for the Hellio Messaging API v1.

### Added
- `Hellio::Client` with Bearer-token auth and one method per endpoint:
  - Account: `balance`, `pricing`.
  - SMS: `sms`, `message`, `campaign`.
  - OTP: `otp`, `verify_otp`, `verify` (channels `sms`, `email`, `voice`).
  - Voice: `voice`, `voice_status`.
  - Number lookup (HLR): `lookup`, `lookups`, `lookup_result`.
  - Email verification: `verify_email`.
  - Webhooks: `webhooks`, `create_webhook`, `delete_webhook`.
- Recipient normalization: methods accept a single string, a comma-separated
  string, or an array.
- Typed errors: `Hellio::InvalidApiTokenError` (401),
  `Hellio::InsufficientBalanceError` (402), `Hellio::ValidationError` (422, with
  `#errors`), `Hellio::RateLimitError` (429), and `Hellio::Error` (base). Each
  carries `status_code` and the parsed `response` body.
- Configuration via constructor or the `HELLIO_API_TOKEN`, `HELLIO_BASE_URL`,
  and `HELLIO_DEFAULT_SENDER` environment variables.
- Pluggable HTTP adapter (defaults to the standard library `net/http`) so tests
  can inject a fake transport.
- RSpec suite with WebMock and a GitHub Actions matrix (Ruby 3.1, 3.2, 3.3).
