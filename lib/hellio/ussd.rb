# frozen_string_literal: true

module Hellio
  # USSD service, reached through Hellio::Client#ussd. It covers pricing and
  # availability lookups, USSD apps (the callback endpoints Hellio calls during a
  # session), rented extensions (the short codes subscribers dial), sessions, and
  # a simulator for exercising an app's callback without a live dial.
  #
  # Apps carry two modes, "test" and "live". A new app starts in "test" and
  # exposes both a `test_secret` (prefix "ussk_test_") and a `live_secret`
  # (prefix "ussk_live_"); `mode`/`is_live` say which one is active. Switching an
  # app to "live" requires a purchased USSD extension. Extension rentals draw
  # from a dedicated USSD balance, separate from SMS credit and the main wallet.
  #
  # Requests are routed through the owning client, so responses are decoded to a
  # Hash with string keys (payloads under "data") and non-2xx responses raise the
  # same typed Hellio::Error subclasses. A rented-out extension returns 409
  # (Hellio::ConflictError), an underfunded USSD balance returns 402
  # (Hellio::InsufficientBalanceError, slug "insufficient_ussd_balance"), and
  # going live before an extension is purchased returns 402
  # (Hellio::ExtensionRequiredError, slug "extension_required").
  #
  # App and extension ids are UUID strings.
  class Ussd
    def initialize(client)
      @client = client
    end

    # ---------------------------------------------------------------- Pricing

    # Short code, currency, per-network session prices, and extension prices.
    def pricing
      get("ussd/pricing")
    end

    # Whether a proposed extension code is valid and available to rent, with its
    # monthly price when available.
    def availability(code)
      get("ussd/pricing/availability", "code" => code)
    end

    # ------------------------------------------------------------------- Apps

    # List your USSD apps.
    def apps
      get("ussd/apps")
    end

    # Create a USSD app. `callback_url` is where Hellio POSTs each session step.
    # The returned "data" includes the app `id` (UUID string), `name`,
    # `callback_url`, `mode` ("test" by default), `test_secret` ("ussk_test_..."),
    # `live_secret` ("ussk_live_..."), `is_live`, and `active`.
    def create_app(name:, callback_url:)
      post("ussd/apps", compact(
        "name" => name,
        "callback_url" => callback_url
      ))
    end

    # Update a USSD app (`id` is a UUID string). Pass only the fields you want to
    # change.
    def update_app(id, name: nil, callback_url: nil, active: nil)
      put("ussd/apps/#{id}", compact(
        "name" => name,
        "callback_url" => callback_url,
        "active" => active
      ))
    end

    # Switch a USSD app's mode (`id` is a UUID string; `mode` is "test" or
    # "live"). Returns the app. Switching to "live" before a USSD extension is
    # purchased raises Hellio::ExtensionRequiredError (402).
    def set_mode(id, mode)
      post("ussd/apps/#{id}/mode", "mode" => mode)
    end

    # Rotate a USSD app's secret for one mode (`id` is a UUID string; `mode` is
    # "test" or "live"). Returns the app with the freshly rotated secret. The old
    # secret for that mode stops working immediately.
    def rotate_secret(id, mode)
      post("ussd/apps/#{id}/rotate-secret", "mode" => mode)
    end

    # Delete a USSD app by id (UUID string).
    def delete_app(id)
      delete("ussd/apps/#{id}")
    end

    # ------------------------------------------------------------- Extensions

    # List your rented extensions.
    def extensions
      get("ussd/extensions")
    end

    # Rent an extension by code, optionally attaching it to an app (`app_id` is a
    # UUID string). Rentals draw from the dedicated USSD balance. Raises
    # Hellio::ConflictError (409) if the code is no longer available and
    # Hellio::InsufficientBalanceError (402, slug "insufficient_ussd_balance") if
    # the USSD balance is too low.
    def rent_extension(code, app_id: nil)
      post("ussd/extensions", compact(
        "code" => code,
        "app_id" => app_id
      ))
    end

    # Release a rented extension by id (UUID string).
    def release_extension(id)
      delete("ussd/extensions/#{id}")
    end

    # --------------------------------------------------------------- Sessions

    # List USSD sessions, optionally filtered by status (e.g. "ended").
    def sessions(status: nil)
      get("ussd/sessions", compact("status" => status))
    end

    # Fetch a single session by id (UUID string).
    def session(id)
      get("ussd/sessions/#{id}")
    end

    # -------------------------------------------------------------- Simulator

    # Simulate a USSD step against an app's callback. `app_id` (UUID string) is
    # the app to drive. Pass `new_session: true` for the first step (dialing the
    # code) and reuse the same `session_id` on follow-up steps. `service_code` is
    # optional and defaults server-side to the shared short code; pass it only to
    # override. Simulation is always sandboxed (no charge, no extension needed).
    # A not-owned `app_id` raises Hellio::ValidationError (422, slug
    # "unknown_app"). Returns the app's reply plus the `action` ("continue" or
    # "end").
    def simulate(app_id:, session_id:, msisdn:, input: "", new_session: false, service_code: nil)
      post("ussd/simulate", compact(
        "app_id" => app_id,
        "session_id" => session_id,
        "msisdn" => msisdn,
        "input" => input,
        "new_session" => new_session,
        "service_code" => service_code
      ))
    end

    # --------------------------------------------------------------- internals

    private

    def get(path, query = {})
      @client.__send__(:get, path, query)
    end

    def post(path, body = {})
      @client.__send__(:post, path, body)
    end

    def put(path, body = {})
      @client.__send__(:put, path, body)
    end

    def delete(path)
      @client.__send__(:delete, path)
    end

    # Drop keys whose value is nil so they are omitted from the request.
    def compact(hash)
      hash.reject { |_, v| v.nil? }
    end
  end
end
