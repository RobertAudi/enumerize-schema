# frozen_string_literal: true

require_relative "lib/enumerize_schema/version"

Gem::Specification.new do |spec|
  spec.name = "enumerize-schema"
  spec.version = EnumerizeSchema::VERSION
  spec.authors = ["Robert Audi"]
  spec.email = ["robert@robertaudi.com"]

  spec.summary = "Store Enumerize enum values in schema files"
  spec.description = "A wrapper around Enumerize to store enum values in schema files"
  spec.homepage = "https://github.com/RobertAudi/enumerize-schema"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/RobertAudi/enumerize-schema"
  spec.metadata["changelog_uri"] = "#{spec.metadata["source_code_uri"]}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:spec/|\.git)})
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "enumerize", "~> 2.5.0"
  spec.add_dependency "activesupport", ">= 3.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rspec", "~> 3.2"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "yard", "~> 0.9"
end
