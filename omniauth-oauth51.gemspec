lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/oauth51/version'

Gem::Specification.new do |gem|
  gem.add_dependency 'omniauth',   '~> 1.2'
  gem.add_dependency 'omniauth-oauth2', '~> 1.1'

  gem.add_development_dependency 'bundler', '~> 1.0'

  gem.authors       = ['Enrico Carlesso']
  gem.email         = ['enricocarlesso@gmail.com']
  gem.description   = 'An OmniAuth strategy for OAuth51 Server.'
  gem.summary       = gem.description
  gem.homepage      = 'https://github.com/coders51/omniauth-oauth51'
  gem.licenses      = %w(MIT)

  gem.executables   = `git ls-files -- bin/*`.split("\n").collect { |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = 'omniauth-oauth51'
  gem.require_paths = %w(lib)
  gem.version       = OmniAuth::Oauth51::VERSION
end
