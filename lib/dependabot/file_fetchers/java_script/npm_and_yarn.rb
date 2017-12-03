# frozen_string_literal: true

require "dependabot/file_fetchers/base"
require "dependabot/file_parsers/java_script/npm_and_yarn"

module Dependabot
  module FileFetchers
    module JavaScript
      class NpmAndYarn < Dependabot::FileFetchers::Base
        def self.required_files_in?(filenames)
          filenames.include?("package.json")
        end

        def self.required_files_message
          "Repo must contain a package.json."
        end

        private

        def fetch_files
          fetched_files = []
          fetched_files << package_json
          fetched_files << package_lock if package_lock
          fetched_files << yarn_lock if yarn_lock
          fetched_files << npmrc if npmrc
          fetched_files << lerna_json if lerna_json
          fetched_files += path_dependencies
          fetched_files += workspace_package_jsons
          fetched_files += lerna_packages
          fetched_files
        end

        def package_json
          @package_json ||= fetch_file_from_github("package.json")
        end

        def package_lock
          @package_lock ||= fetch_file_if_present("package-lock.json")
        end

        def yarn_lock
          @yarn_lock ||= fetch_file_if_present("yarn.lock")
        end

        def npmrc
          @npmrc ||= fetch_file_if_present(".npmrc")
        end

        def lerna_json
          @lerna ||= fetch_file_if_present("lerna.json")
        end

        def path_dependencies
          package_json_files = []
          unfetchable_deps = []

          types = FileParsers::JavaScript::NpmAndYarn::DEPENDENCY_TYPES
          parsed_package_json.values_at(*types).compact.each do |deps|
            deps.map do |name, version|
              next unless version.start_with?("file:")

              path = version.sub(/^file:/, "")
              file = File.join(path, "package.json")

              begin
                package_json_files << fetch_file_from_github(file)
              rescue Dependabot::DependencyFileNotFound
                unfetchable_deps << name
              end
            end
          end

          if unfetchable_deps.any?
            raise Dependabot::PathDependenciesNotReachable, unfetchable_deps
          end

          package_json_files
        end

        def workspace_package_jsons
          return [] unless parsed_package_json["workspaces"]
          package_json_files = []
          unfetchable_deps = []

          parsed_package_json["workspaces"].each do |path|
            workspaces =
              if path.end_with?("*") then expand_paths(path)
              else [path]
              end

            workspaces.each do |workspace|
              file = File.join(workspace, "package.json")

              begin
                package_json_files << fetch_file_from_github(file)
              rescue Dependabot::DependencyFileNotFound
                unfetchable_deps << file
              end
            end
          end

          if unfetchable_deps.any?
            raise Dependabot::PathDependenciesNotReachable, unfetchable_deps
          end

          package_json_files
        end

        def lerna_packages
          return [] unless lerna_json
          return [] unless parsed_lerna_json["packages"]
          package_files = []
          unfetchable_deps = []

          parsed_lerna_json["packages"].each do |path|
            packages =
              if path.end_with?("*") then expand_paths(path)
              else [path]
              end

            packages.each do |package|
              file = File.join(package, "package.json")

              begin
                package_files << fetch_file_from_github(file)
              rescue Dependabot::DependencyFileNotFound
                unfetchable_deps << file
              end
            end
          end

          if unfetchable_deps.any?
            raise Dependabot::PathDependenciesNotReachable, unfetchable_deps
          end

          package_files
        end

        def expand_paths(path)
          dir = directory.gsub(%r{(^/|/$)}, "")
          path = File.join(dir, path.gsub(/\*$/, ""))
          path = Pathname.new(path).cleanpath.to_path
          github_client.contents(repo, path: path, ref: commit).
            select { |file| file.type == "dir" }.
            map { |f| f.path.gsub(%r{^/?#{Regexp.escape(dir)}/?}, "") }
        end

        def parsed_package_json
          JSON.parse(package_json.content)
        rescue JSON::ParserError
          raise Dependabot::DependencyFileNotParseable, package_json.path
        end

        def parsed_lerna_json
          JSON.parse(lerna_json.content)
        rescue JSON::ParserError
          raise Dependabot::DependencyFileNotParseable, lerna_json.path
        end
      end
    end
  end
end
