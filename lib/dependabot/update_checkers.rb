# frozen_string_literal: true

require "dependabot/update_checkers/ruby/bundler"
require "dependabot/update_checkers/python/pip"
require "dependabot/update_checkers/java_script/npm_and_yarn"
require "dependabot/update_checkers/java/maven"
require "dependabot/update_checkers/php/composer"
require "dependabot/update_checkers/git/submodules"
require "dependabot/update_checkers/docker/docker"
require "dependabot/update_checkers/dotnet/nuget"

module Dependabot
  module UpdateCheckers
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.for_package_manager(package_manager)
      case package_manager
      when "bundler" then UpdateCheckers::Ruby::Bundler
      when "npm_and_yarn" then UpdateCheckers::JavaScript::NpmAndYarn
      when "maven" then UpdateCheckers::Java::Maven
      when "pip" then UpdateCheckers::Python::Pip
      when "pipfile" then UpdateCheckers::Python::Pip
      when "composer" then UpdateCheckers::Php::Composer
      when "submodules" then UpdateCheckers::Git::Submodules
      when "docker" then UpdateCheckers::Docker::Docker
      when "nuget" then UpdateCheckers::Dotnet::Nuget
      else raise "Unsupported package_manager #{package_manager}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
