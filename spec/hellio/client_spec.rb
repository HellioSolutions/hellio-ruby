# frozen_string_literal: true

RSpec.describe Hellio::Client do
  let(:base_url) { "https://api.helliomessaging.com/v1" }
  let(:token)    { "test-token" }
  let(:client)   { described_class.new(token: token, default_sender: "HellioSMS") }

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

  describe "#balance (GET)" do
    it "returns the decoded body" do
      stub_hellio(:get, "balance", response_body: { "data" => { "balance" => "195.0000" } })

      result = client.balance

      expect(result).to eq("data" => { "balance" => "195.0000" })
    end
  end

  describe "#pricing" do
    it "omits the country query when not given" do
      stub = stub_hellio(:get, "pricing", response_body: { "data" => [] })

      client.pricing

      expect(stub).to have_been_requested
    end

    it "adds a country filter when given" do
      stub = stub_request(:get, "#{base_url}/pricing")
        .with(query: { "country" => "GH" })
        .to_return(status: 200, body: JSON.generate("data" => []))

      client.pricing("GH")

      expect(stub).to have_been_requested
    end
  end

  describe "#sms" do
    it "posts recipients as a list and uses the default sender" do
      stub = stub_hellio(
        :post, "sms/send",
        request_body: { "recipients" => ["233241234567"], "sender" => "HellioSMS", "message" => "Hello!" },
        response_body: { "data" => { "status" => "queued" } }
      )

      result = client.sms("233241234567", "Hello!")

      expect(stub).to have_been_requested
      expect(result).to eq("data" => { "status" => "queued" })
    end

    it "lets a per-call sender and gateway override" do
      stub = stub_hellio(
        :post, "sms/send",
        request_body: {
          "recipients" => %w[233241234567 233201234567],
          "sender" => "BRAND", "message" => "Hi all", "gateway" => "premium"
        }
      )

      client.sms(%w[233241234567 233201234567], "Hi all", sender: "BRAND", gateway: "premium")

      expect(stub).to have_been_requested
    end
  end

  describe "recipient normalization" do
    it "splits and trims a comma-separated string" do
      stub = stub_hellio(
        :post, "sms/send",
        request_body: { "recipients" => %w[233241234567 233201234567], "sender" => "HellioSMS", "message" => "Hi" }
      )

      client.sms("233241234567, 233201234567", "Hi")

      expect(stub).to have_been_requested
    end

    it "passes an array through unchanged" do
      stub = stub_hellio(
        :post, "lookup",
        request_body: { "numbers" => %w[233241234567] }
      )

      client.lookup(["233241234567"])

      expect(stub).to have_been_requested
    end
  end

  describe "#otp" do
    it "sends a mobile_number for the sms channel" do
      stub = stub_hellio(
        :post, "otp/send",
        request_body: { "channel" => "sms", "mobile_number" => "233241234567", "sender" => "HellioSMS", "length" => 6 }
      )

      client.otp("233241234567", sender: "HellioSMS", length: 6)

      expect(stub).to have_been_requested
    end

    it "sends an email for the email channel and omits nil fields" do
      stub = stub_hellio(
        :post, "otp/send",
        request_body: { "channel" => "email", "email" => "user@example.com" }
      )

      client.otp("user@example.com", channel: "email")

      expect(stub).to have_been_requested
    end
  end

  describe "#verify_otp and #verify" do
    it "verify_otp returns the full response" do
      stub_hellio(
        :post, "otp/verify",
        request_body: { "channel" => "sms", "mobile_number" => "233241234567", "code" => "123456" },
        response_body: { "data" => { "verified" => true } }
      )

      expect(client.verify_otp("233241234567", "123456")).to eq("data" => { "verified" => true })
    end

    it "verify returns true when data.verified is truthy" do
      stub_hellio(:post, "otp/verify", response_body: { "data" => { "verified" => true } })

      expect(client.verify("233241234567", "123456")).to be(true)
    end

    it "verify returns false when data.verified is falsey" do
      stub_hellio(:post, "otp/verify", response_body: { "data" => { "verified" => false } })

      expect(client.verify("233241234567", "000000")).to be(false)
    end

    it "verify returns false on a 422 validation error" do
      stub_hellio(:post, "otp/verify", status: 422, response_body: { "message" => "Invalid code" })

      expect(client.verify("233241234567", "000000")).to be(false)
    end
  end

  describe "error mapping" do
    {
      401 => Hellio::InvalidApiTokenError,
      402 => Hellio::InsufficientBalanceError,
      422 => Hellio::ValidationError,
      429 => Hellio::RateLimitError,
      500 => Hellio::Error
    }.each do |status, error_class|
      it "raises #{error_class} on #{status}" do
        stub_hellio(:get, "balance", status: status, response_body: { "message" => "boom" })

        expect { client.balance }.to raise_error(error_class) do |error|
          expect(error).to be_a(Hellio::Error)
          expect(error.message).to eq("boom")
          expect(error.status_code).to eq(status)
          expect(error.response).to eq("message" => "boom")
        end
      end
    end

    it "exposes field errors on a 422 ValidationError" do
      stub_hellio(
        :post, "sms/send",
        status: 422,
        response_body: { "message" => "Validation failed", "errors" => { "recipients" => ["required"] } }
      )

      expect { client.sms("233241234567", "Hi") }.to raise_error(Hellio::ValidationError) do |error|
        expect(error.errors).to eq("recipients" => ["required"])
      end
    end

    it "falls back to a default message when the body has none" do
      stub_hellio(:get, "balance", status: 500, response_body: {})

      expect { client.balance }.to raise_error(Hellio::Error, "Hellio API request failed.")
    end
  end

  describe "webhooks" do
    it "omits events when empty" do
      stub = stub_hellio(:post, "webhooks", request_body: { "url" => "https://example.com/hook" })

      client.create_webhook("https://example.com/hook")

      expect(stub).to have_been_requested
    end

    it "includes events when given" do
      stub = stub_hellio(
        :post, "webhooks",
        request_body: { "url" => "https://example.com/hook", "events" => ["message.delivered"] }
      )

      client.create_webhook("https://example.com/hook", events: ["message.delivered"])

      expect(stub).to have_been_requested
    end

    it "deletes by id" do
      stub = stub_request(:delete, "#{base_url}/webhooks/1").to_return(status: 200, body: "{}")

      client.delete_webhook(1)

      expect(stub).to have_been_requested
    end
  end

  describe "configuration" do
    it "reads config from the environment" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HELLIO_API_TOKEN").and_return("env-token")
      allow(ENV).to receive(:[]).with("HELLIO_BASE_URL").and_return("https://example.test/v1")
      allow(ENV).to receive(:[]).with("HELLIO_DEFAULT_SENDER").and_return("ENVSENDER")

      c = described_class.new

      expect(c.base_url).to eq("https://example.test/v1")
      expect(c.default_sender).to eq("ENVSENDER")
    end

    it "strips trailing slashes from the base URL" do
      c = described_class.new(token: "t", base_url: "https://example.test/v1/")
      expect(c.base_url).to eq("https://example.test/v1")
    end

    it "accepts an injected HTTP adapter" do
      fake = Class.new do
        attr_reader :calls
        def initialize
          @calls = []
        end

        def call(**args)
          @calls << args
          Hellio::Response.new(200, JSON.generate("data" => { "ok" => true }))
        end
      end.new

      c = described_class.new(token: "t", http: fake)
      result = c.balance

      expect(result).to eq("data" => { "ok" => true })
      expect(fake.calls.first[:method]).to eq(:get)
      expect(fake.calls.first[:url]).to eq("#{base_url}/balance")
    end
  end
end
