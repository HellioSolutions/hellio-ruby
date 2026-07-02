# frozen_string_literal: true

require_relative "lib/hellio/version"

Gem::Specification.new do |spec|
  spec.name          = "hellio-messaging"
  spec.version       = Hellio::VERSION
  spec.authors       = ["Albert Ninyeh"]
  spec.email         = ["eaglesecurity0@gmail.com"]

  spec.summary       = "Official Ruby SDK for the Hellio Messaging API v1."
  spec.description   = "Ruby client for the Hellio Messaging API v1: SMS, OTP " \
                       "(SMS / email / voice), voice broadcasts, number lookup (HLR), " \
                       "email verification, pricing, balance, and webhooks."
  spec.homepage      = "https://github.com/HellioSolutions/hellio-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "source_code_uri"   => spec.homepage,
    "changelog_uri"     => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"   => "#{spec.homepage}/issues",
    "documentation_uri" => "https://helliomessaging.com"
  }

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "CHANGELOG.md",
    "LICENSE"
  ]
  spec.require_paths = ["lib"]

  # Runtime uses only the Ruby standard library (net/http, json).

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.19"
end
