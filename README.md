# HellioMessaging

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/helliomessaging`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'helliomessaging'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install helliomessaging

## Usage

Register on https://www.helliomessaging.com and get user details, set them in your ENV VARS

      client_id            = ENV['HELLIO_MESSAGING_CIENT_ID']
      application_secret   = ENV['HELLIO_MESSAGING_APPLICATION_SECRET']
      sender_id            = ENV['HELLIO_MESSAGING_SENDER_ID']


      To Send SMS Add helliomessaging gem in your Gemfile

      gem 'helliomessaging', git: "https://github.com/helliosolutions/helliomessaging-ruby.git", branch: :master

      Add call following method to send sms

      HellioMessaging::Sms.send("your message text goes here", "your mobile numbers")

      Ex: HellioMessaging::Sms.send("123456 is your mobile verification OTP.", "233242813656")

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/helliomessaging.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
