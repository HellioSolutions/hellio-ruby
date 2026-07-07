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

    it "creates an app" do
      stub = stub_hellio(
        :post, "ussd/apps",
        request_body: { "name" => "Airtime", "callback_url" => "https://app.test/ussd" },
        status: 201,
        response_body: { "data" => { "id" => 1 } }
      )

      result = client.ussd.create_app(name: "Airtime", callback_url: "https://app.test/ussd")

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "id" => 1 })
    end

    it "updates only the fields given" do
      stub = stub_hellio(
        :put, "ussd/apps/1",
        request_body: { "active" => false }
      )

      client.ussd.update_app(1, active: false)

      expect(stub).to have_been_requested
    end

    it "deletes an app" do
      stub = stub_request(:delete, "#{base_url}/ussd/apps/1").to_return(status: 204, body: "")

      client.ussd.delete_app(1)

      expect(stub).to have_been_requested
    end
  end

  describe "extensions" do
    it "lists extensions" do
      stub = stub_hellio(:get, "ussd/extensions", response_body: { "data" => [] })

      client.ussd.extensions

      expect(stub).to have_been_requested
    end

    it "rents an extension with an optional app_id" do
      stub = stub_hellio(
        :post, "ussd/extensions",
        request_body: { "code" => "100", "app_id" => 7 },
        status: 201,
        response_body: { "data" => { "id" => 42 } }
      )

      client.ussd.rent_extension("100", app_id: 7)

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

    it "raises InsufficientBalanceError on 402" do
      stub_hellio(
        :post, "ussd/extensions",
        status: 402,
        response_body: { "error" => "insufficient_balance" }
      )

      expect { client.ussd.rent_extension("100") }
        .to raise_error(Hellio::InsufficientBalanceError) do |error|
          expect(error.status_code).to eq(402)
          expect(error.message).to eq("insufficient_balance")
        end
    end

    it "releases an extension" do
      stub = stub_request(:delete, "#{base_url}/ussd/extensions/42").to_return(status: 204, body: "")

      client.ussd.release_extension(42)

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

    it "fetches a single session" do
      stub = stub_hellio(:get, "ussd/sessions/1024", response_body: { "data" => { "id" => 1024 } })

      client.ussd.session(1024)

      expect(stub).to have_been_requested
    end
  end

  describe "#simulate" do
    it "posts the step and omits nil fields" do
      stub = stub_hellio(
        :post, "ussd/simulate",
        request_body: {
          "msisdn" => "233241234567",
          "service_code" => "*920*100#",
          "new_session" => true
        },
        response_body: { "data" => { "message" => "Welcome", "action" => "continue" } }
      )

      result = client.ussd.simulate(msisdn: "233241234567", service_code: "*920*100#", new_session: true)

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "message" => "Welcome", "action" => "continue" })
    end

    it "carries the session_id and input on a follow-up step" do
      stub = stub_hellio(
        :post, "ussd/simulate",
        request_body: {
          "session_id" => "sess_1",
          "msisdn" => "233241234567",
          "service_code" => "*920*100#",
          "input" => "1"
        }
      )

      client.ussd.simulate(
        msisdn: "233241234567", service_code: "*920*100#",
        session_id: "sess_1", input: "1"
      )

      expect(stub).to have_been_requested
    end
  end
end
