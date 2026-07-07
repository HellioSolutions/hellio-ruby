# frozen_string_literal: true

RSpec.describe Hellio::Ussd do
  let(:base_url) { "https://api.helliomessaging.com/v1" }
  let(:token)    { "test-token" }
  let(:client)   { Hellio::Client.new(token: token) }

  def stub_hellio(method, path, status: 200, request_body: nil, response_body: {})
    stub = stub_request(method, "#{base_url}/#{path}")
      .with(headers: {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      })
    stub = stub.with(body: request_body) unless request_body.nil?
    stub.to_return(
      status: status,
      body: JSON.generate(response_body),
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "is memoized on the client" do
    expect(client.ussd).to be_a(described_class)
    expect(client.ussd).to equal(client.ussd)
  end

  describe "#pricing" do
    it "gets the pricing table" do
      stub = stub_hellio(:get, "ussd/pricing", response_body: { "data" => { "short_code" => "920" } })

      expect(client.ussd.pricing).to eq("data" => { "short_code" => "920" })
      expect(stub).to have_been_requested
    end
  end

  describe "#availability" do
    it "passes the code as a query parameter" do
      stub = stub_request(:get, "#{base_url}/ussd/pricing/availability")
        .with(query: { "code" => "100" })
        .to_return(status: 200, body: JSON.generate("data" => { "available" => true }))

      client.ussd.availability("100")

      expect(stub).to have_been_requested
    end
  end

  describe "apps" do
    it "lists apps" do
      stub = stub_hellio(:get, "ussd/apps", response_body: { "data" => [] })

      client.ussd.apps

      expect(stub).to have_been_requested
    end

    it "creates an app that starts in test mode with both secrets" do
      app = {
        "id" => "8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678",
        "name" => "Airtime",
        "callback_url" => "https://app.test/ussd",
        "mode" => "test",
        "test_secret" => "ussk_test_abc123",
        "live_secret" => "ussk_live_def456",
        "is_live" => false,
        "active" => true
      }
      stub = stub_hellio(
        :post, "ussd/apps",
        request_body: { "name" => "Airtime", "callback_url" => "https://app.test/ussd" },
        status: 201,
        response_body: { "data" => app }
      )

      result = client.ussd.create_app(name: "Airtime", callback_url: "https://app.test/ussd")

      expect(stub).to have_been_requested
      expect(result).to eq("data" => app)
    end

    it "updates only the fields given (id is a UUID string)" do
      stub = stub_hellio(
        :put, "ussd/apps/8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678",
        request_body: { "active" => false }
      )

      client.ussd.update_app("8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678", active: false)

      expect(stub).to have_been_requested
    end

    it "switches an app's mode" do
      stub = stub_hellio(
        :post, "ussd/apps/8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678/mode",
        request_body: { "mode" => "live" },
        response_body: { "data" => { "mode" => "live", "is_live" => true } }
      )

      result = client.ussd.set_mode("8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678", "live")

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "mode" => "live", "is_live" => true })
    end

    it "raises ExtensionRequiredError when going live without an extension (402)" do
      stub_hellio(
        :post, "ussd/apps/8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678/mode",
        status: 402,
        response_body: { "error" => "extension_required" }
      )

      expect { client.ussd.set_mode("8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678", "live") }
        .to raise_error(Hellio::ExtensionRequiredError) do |error|
          expect(error).to be_a(Hellio::Error)
          expect(error.status_code).to eq(402)
          expect(error.message).to eq("extension_required")
        end
    end

    it "rotates a secret for a mode" do
      stub = stub_hellio(
        :post, "ussd/apps/8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678/rotate-secret",
        request_body: { "mode" => "test" },
        response_body: { "data" => { "test_secret" => "ussk_test_new789" } }
      )

      result = client.ussd.rotate_secret("8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678", "test")

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "test_secret" => "ussk_test_new789" })
    end

    it "deletes an app by UUID" do
      stub = stub_request(:delete, "#{base_url}/ussd/apps/8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678")
        .to_return(status: 204, body: "")

      client.ussd.delete_app("8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678")

      expect(stub).to have_been_requested
    end
  end

  describe "extensions" do
    it "lists extensions" do
      stub = stub_hellio(:get, "ussd/extensions", response_body: { "data" => [] })

      client.ussd.extensions

      expect(stub).to have_been_requested
    end

    it "rents an extension with an optional app_id (UUID string)" do
      stub = stub_hellio(
        :post, "ussd/extensions",
        request_body: { "code" => "100", "app_id" => "8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678" },
        status: 201,
        response_body: { "data" => { "id" => "a1b2c3d4-0000-4000-8000-000000000042" } }
      )

      client.ussd.rent_extension("100", app_id: "8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678")

      expect(stub).to have_been_requested
    end

    it "omits app_id when not given" do
      stub = stub_hellio(
        :post, "ussd/extensions",
        request_body: { "code" => "100" },
        status: 201
      )

      client.ussd.rent_extension("100")

      expect(stub).to have_been_requested
    end

    it "raises ConflictError when the extension is unavailable (409)" do
      stub_hellio(
        :post, "ussd/extensions",
        status: 409,
        response_body: { "error" => "extension_unavailable" }
      )

      expect { client.ussd.rent_extension("100") }.to raise_error(Hellio::ConflictError) do |error|
        expect(error).to be_a(Hellio::Error)
        expect(error.status_code).to eq(409)
        expect(error.message).to eq("extension_unavailable")
        expect(error.response).to eq("error" => "extension_unavailable")
      end
    end

    it "raises InsufficientBalanceError on 402 insufficient_ussd_balance" do
      stub_hellio(
        :post, "ussd/extensions",
        status: 402,
        response_body: { "error" => "insufficient_ussd_balance" }
      )

      expect { client.ussd.rent_extension("100") }
        .to raise_error(Hellio::InsufficientBalanceError) do |error|
          expect(error.status_code).to eq(402)
          expect(error.message).to eq("insufficient_ussd_balance")
        end
    end

    it "releases an extension by UUID" do
      stub = stub_request(:delete, "#{base_url}/ussd/extensions/a1b2c3d4-0000-4000-8000-000000000042")
        .to_return(status: 204, body: "")

      client.ussd.release_extension("a1b2c3d4-0000-4000-8000-000000000042")

      expect(stub).to have_been_requested
    end
  end

  describe "sessions" do
    it "filters by status when given" do
      stub = stub_request(:get, "#{base_url}/ussd/sessions")
        .with(query: { "status" => "ended" })
        .to_return(status: 200, body: JSON.generate("data" => []))

      client.ussd.sessions(status: "ended")

      expect(stub).to have_been_requested
    end

    it "omits the status query when not given" do
      stub = stub_hellio(:get, "ussd/sessions", response_body: { "data" => [] })

      client.ussd.sessions

      expect(stub).to have_been_requested
    end

    it "fetches a single session by UUID" do
      stub = stub_hellio(
        :get, "ussd/sessions/6f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f",
        response_body: { "data" => { "id" => "6f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f" } }
      )

      client.ussd.session("6f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f")

      expect(stub).to have_been_requested
    end
  end

  describe "#simulate" do
    let(:app_id) { "8f14e45f-ea0a-4c9b-9f2e-1d2c3b4a5678" }

    it "posts the first step with defaults and omits service_code when nil" do
      stub = stub_hellio(
        :post, "ussd/simulate",
        request_body: {
          "app_id" => app_id,
          "session_id" => "sess_1",
          "msisdn" => "233241234567",
          "input" => "",
          "new_session" => true
        },
        response_body: { "data" => { "message" => "Welcome", "action" => "continue" } }
      )

      result = client.ussd.simulate(
        app_id: app_id, session_id: "sess_1", msisdn: "233241234567", new_session: true
      )

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "message" => "Welcome", "action" => "continue" })
    end

    it "carries the input on a follow-up step and defaults new_session to false" do
      stub = stub_hellio(
        :post, "ussd/simulate",
        request_body: {
          "app_id" => app_id,
          "session_id" => "sess_1",
          "msisdn" => "233241234567",
          "input" => "1",
          "new_session" => false
        }
      )

      client.ussd.simulate(
        app_id: app_id, session_id: "sess_1", msisdn: "233241234567", input: "1"
      )

      expect(stub).to have_been_requested
    end

    it "sends service_code only when given" do
      stub = stub_hellio(
        :post, "ussd/simulate",
        request_body: {
          "app_id" => app_id,
          "session_id" => "sess_1",
          "msisdn" => "233241234567",
          "input" => "",
          "new_session" => true,
          "service_code" => "*920*100#"
        }
      )

      client.ussd.simulate(
        app_id: app_id, session_id: "sess_1", msisdn: "233241234567",
        new_session: true, service_code: "*920*100#"
      )

      expect(stub).to have_been_requested
    end

    it "raises ValidationError when the app is not owned (422 unknown_app)" do
      stub_hellio(
        :post, "ussd/simulate",
        status: 422,
        response_body: { "error" => "unknown_app" }
      )

      expect do
        client.ussd.simulate(app_id: app_id, session_id: "sess_1", msisdn: "233241234567")
      end.to raise_error(Hellio::ValidationError) do |error|
        expect(error.status_code).to eq(422)
        expect(error.message).to eq("unknown_app")
      end
    end
  end
end
