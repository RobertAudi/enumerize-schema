# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"
require "yard"

RSpec::Core::RakeTask.new(:spec) do |t|
  if ENV["GITHUB_ACTIONS"]
    t.rspec_opts = [
      "--format RSpec::Github::Formatter",
      "--format documentation",
      "--force-color"
    ]
  end
end

YARD::Rake::YardocTask.new do |t|
  t.files = ["lib/**/*.rb"]
end

task default: [:standard, :spec]
