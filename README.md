# Hellio Messaging's REST API for Ruby

This repository contains the open source Ruby client for Hellio Messaging's REST API. Documentation can be found at: https://docs.helliomessaging.com/

The documentation for the Hellio Messaging API can be found here.https://docs.helliomessaging.com/

## Requirements

- [Sign up](https://app.helliomessaging.com/try-hellio) for a free Hellio Messaging account
- Create a new grab your `client_id` and your `application_secret` from your account settings
- Hellio Messaging's API client for Ruby requires Ruby >= 2.0 and above

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hellio-ruby'
```

To install using Bundler grab the latest stable version:

```ruby
gem 'hellio-ruby', '~> 1.1.0'
```

To manually install hellio-ruby via Rubygems simply gem install:

    $ gem install hellio-ruby

## Getting Started

Register on https://app.helliomessaging.com/try-hellio and get user details, set them in your ENV VARS

```ruby
      client_id            = ENV['HELLIO_MESSAGING_CIENT_ID']
      application_secret   = ENV['HELLIO_MESSAGING_APPLICATION_SECRET']
      sender_id            = ENV['HELLIO_MESSAGING_SENDER_ID']


      To Send SMS Add hellio-ruby gem in your Gemfile

      gem 'hellio-ruby', git: "https://github.com/HellioSolutions/hellio-ruby.git", branch: :master

      Add call following method to send sms

      HellioMessaging::SMS.send("your message text goes here", "your mobile numbers")

      Ex: HellioMessaging::SMS.send("123456 is your mobile verification OTP.", "233242813656")
```

## Getting help

If you need help installing or using the library, please check the [Hellio Messaging Support Help Center](https://helliomessaging.com/contact).

If you've instead found a bug in the library or would like new features added, go ahead and open issues or pull requests against this repo!

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/HellioSolutions/hellio-ruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
