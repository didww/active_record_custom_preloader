
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record_custom_preloader/version"

Gem::Specification.new do |spec|
  spec.name          = 'active_record_custom_preloader'
  spec.version       = ActiveRecordCustomPreloader::VERSION
  spec.authors       = ['Denis Talakevich']
  spec.email         = ['senid231@gmail.com']

  spec.summary       = %q{Custom preloader for ActiveRecord.}
  spec.description   = %q{Custom preloader for ActiveRecord.}
  spec.homepage      = 'https://github.com/senid231/active_record_custom_preloader'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'activerecord', '>= 6.0.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'sqlite3'
end
