# frozen_string_literal: true

module Hellio
  # USSD service, reached through Hellio::Client#ussd. It covers pricing and
  # availability lookups, USSD apps (the callback endpoints Hellio calls during a
  # session), rented extensions (the short codes subscribers dial), sessions, and
  # a simulator for exercising an app's callback without a live dial.
  #
  # Requests are routed through the owning client, so responses are decoded to a
  # Hash with string keys (payloads under "data") and non-2xx responses raise the
  # same typed Hellio::Error subclasses. A rented-out extension returns 409
  # (Hellio::ConflictError) and an underfunded account returns 402
  # (Hellio::InsufficientBalanceError).
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
    def create_app(name:, callback_url:)
      post("ussd/apps", compact(
        "name" => name,
        "callback_url" => callback_url
      ))
    end

    # Update a USSD app. Pass only the fields you want to change.
    def update_app(id, name: nil, callback_url: nil, active: nil)
      put("ussd/apps/#{id}", compact(
        "name" => name,
        "callback_url" => callback_url,
        "active" => active
      ))
    end

    # Delete a USSD app by id.
    def delete_app(id)
      delete("ussd/apps/#{id}")
    end

    # ------------------------------------------------------------- Extensions

    # List your rented extensions.
    def extensions
      get("ussd/extensions")
    end

    # Rent an extension by code, optionally attaching it to an app. Raises
    # Hellio::ConflictError (409) if the code is no longer available and
    # Hellio::InsufficientBalanceError (402) if the balance is too low.
    def rent_extension(code, app_id: nil)
      post("ussd/extensions", compact(
        "code" => code,
        "app_id" => app_id
      ))
    end

    # Release a rented extension by id.
    def release_extension(id)
      delete("ussd/extensions/#{id}")
    end

    # --------------------------------------------------------------- Sessions

    # List USSD sessions, optionally filtered by status (e.g. "ended").
    def sessions(status: nil)
      get("ussd/sessions", compact("status" => status))
    end

    # Fetch a single session by id.
    def session(id)
      get("ussd/sessions/#{id}")
    end

    # -------------------------------------------------------------- Simulator

    # Simulate a USSD step against an app's callback. Pass `new_session: true`
    # for the first step (dialing the code) and the returned `session_id` on
    # follow-up steps. Returns the app's reply plus the `action` ("continue" or
    # "end").
    def simulate(msisdn:, service_code:, input: nil, session_id: nil, new_session: nil)
      post("ussd/simulate", compact(
        "session_id" => session_id,
        "msisdn" => msisdn,
        "service_code" => service_code,
        "input" => input,
        "new_session" => new_session
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
