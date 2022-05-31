# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'helliomessaging/version'

Gem::Specification.new do |spec|
  spec.name          = "helliomessaging"
  spec.version       = HellioMessaging::VERSION
  spec.authors       = ["VimKanzo"]
  spec.email         = ["eaglesecurity0@gmail.com"]

  spec.summary       = %q{ruby gem to send SMS form hellio messaging SMS API}
  spec.description   = %q{ruby gem to send SMS form hellio messaging SMS API}
  spec.homepage      = ""
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3.14"
  spec.add_development_dependency "rake", "~> 13.0.6"
end
