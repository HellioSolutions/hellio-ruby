# Hellio Messaging's REST API for Ruby

This repository contains the open source Ruby client for Hellio Messaging's REST API. Documentation can be found at: https://docs.helliomessaging.com/

The documentation for the Hellio Messaging API can be found here.https://docs.helliomessaging.com/

## Requirements

    - Sign up for a free Hellio Messaging account
    - Create a new grab your client_id and your application_secret from your account settings
    - Hellio Messaging's API client for Ruby requires Ruby >= 2.0 and above

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hellio-ruby'
```

To install using Bundler grab the latest stable version:

```ruby
gem 'hellio-ruby', '~> 3.1.0'
```

To manually install twilio-ruby via Rubygems simply gem install:

    $ gem install hellio-ruby

## Usage

Register on https://www.helliomessaging.com and get user details, set them in your ENV VARS

      client_id            = ENV['HELLIO_MESSAGING_CIENT_ID']
      application_secret   = ENV['HELLIO_MESSAGING_APPLICATION_SECRET']
      sender_id            = ENV['HELLIO_MESSAGING_SENDER_ID']


      To Send SMS Add helliomessaging gem in your Gemfile

      gem 'helliomessaging', git: "https://github.com/HellioSolutions/hellio-ruby.git", branch: :master

      Add call following method to send sms

      HellioMessaging::Sms.send("your message text goes here", "your mobile numbers")

      Ex: HellioMessaging::Sms.send("123456 is your mobile verification OTP.", "233242813656")

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/HellioSolutions/hellio-ruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
