# frozen_string_literal: true

require "spec_helper"
require "dependabot/dependency_file"
require "dependabot/dependency"
require "dependabot/file_updaters/java/maven"
require_relative "../shared_examples_for_file_updaters"

RSpec.describe Dependabot::FileUpdaters::Java::Maven do
  it_behaves_like "a dependency file updater"

  let(:updater) do
    described_class.new(
      dependency_files: [pom],
      dependencies: dependencies,
      credentials: [
        {
          "host" => "github.com",
          "username" => "x-access-token",
          "password" => "token"
        }
      ]
    )
  end
  let(:dependencies) { [dependency] }
  let(:pom) do
    Dependabot::DependencyFile.new(content: pom_body, name: "pom.xml")
  end
  let(:pom_body) { fixture("java", "poms", "basic_pom.xml") }
  let(:dependency) do
    Dependabot::Dependency.new(
      name: "org.apache.httpcomponents:httpclient",
      version: "4.6.1",
      requirements: [
        {
          file: "pom.xml",
          requirement: "4.6.1",
          groups: [],
          source: nil
        }
      ],
      previous_requirements: [
        {
          file: "pom.xml",
          requirement: "4.5.3",
          groups: [],
          source: nil
        }
      ],
      package_manager: "maven"
    )
  end

  describe "#updated_dependency_files" do
    subject(:updated_files) { updater.updated_dependency_files }

    it "returns DependencyFile objects" do
      updated_files.each { |f| expect(f).to be_a(Dependabot::DependencyFile) }
    end

    its(:length) { is_expected.to eq(1) }

    describe "the updated pom file" do
      subject(:updated_pom_file) do
        updated_files.find { |f| f.name == "pom.xml" }
      end

      its(:content) { is_expected.to include "<version>4.6.1</version>" }
      its(:content) { is_expected.to include "<version>23.3-jre</version>" }

      it "doesn't update the formatting of the POM" do
        expect(updated_pom_file.content).
          to include(%(<project xmlns="http://maven.apache.org/POM/4.0.0"\n))
      end

      context "when the requirement is a hard requirement" do
        let(:pom_body) { fixture("java", "poms", "hard_requirement_pom.xml") }
        let(:dependency) do
          Dependabot::Dependency.new(
            name: "org.apache.httpcomponents:httpclient",
            version: "4.6.1",
            requirements: [
              {
                file: "pom.xml",
                requirement: "[4.6.1]",
                groups: [],
                source: nil
              }
            ],
            previous_requirements: [
              {
                file: "pom.xml",
                requirement: "[4.5.3]",
                groups: [],
                source: nil
              }
            ],
            package_manager: "maven"
          )
        end

        its(:content) { is_expected.to include "<version>[4.6.1]</version>" }
        its(:content) { is_expected.to include "<version>[23.3-jre]</version>" }
      end

      context "with multiple dependencies to be updated" do
        let(:dependencies) do
          [
            Dependabot::Dependency.new(
              name: "org.apache.httpcomponents:httpclient",
              version: "4.6.1",
              requirements: [
                {
                  file: "pom.xml",
                  requirement: "4.6.1",
                  groups: [],
                  source: nil
                }
              ],
              previous_requirements: [
                {
                  file: "pom.xml",
                  requirement: "4.5.3",
                  groups: [],
                  source: nil
                }
              ],
              package_manager: "maven"
            ),
            Dependabot::Dependency.new(
              name: "com.google.guava:guava",
              version: "23.6-jre",
              requirements: [
                {
                  file: "pom.xml",
                  requirement: "23.6-jre",
                  groups: [],
                  source: nil
                }
              ],
              previous_requirements: [
                {
                  file: "pom.xml",
                  requirement: "23.3-jre",
                  groups: [],
                  source: nil
                }
              ],
              package_manager: "maven"
            )
          ]
        end

        its(:content) { is_expected.to include "<version>4.6.1</version>" }
        its(:content) { is_expected.to include "<version>23.6-jre</version>" }
      end

      context "pom with dependency version defined by a property" do
        let(:pom_body) { fixture("java", "poms", "property_pom.xml") }
        let(:dependencies) do
          [
            Dependabot::Dependency.new(
              name: "org.springframework:spring-beans",
              version: "5.0.0.RELEASE",
              requirements: [
                {
                  file: "pom.xml",
                  requirement: "5.0.0.RELEASE",
                  groups: [],
                  source: nil
                }
              ],
              previous_requirements: [
                {
                  file: "pom.xml",
                  requirement: "4.3.12.RELEASE",
                  groups: [],
                  source: nil
                }
              ],
              package_manager: "maven"
            ),
            Dependabot::Dependency.new(
              name: "org.springframework:spring-context",
              version: "5.0.0.RELEASE",
              requirements: [
                {
                  file: "pom.xml",
                  requirement: "5.0.0.RELEASE",
                  groups: [],
                  source: nil
                }
              ],
              previous_requirements: [
                {
                  file: "pom.xml",
                  requirement: "4.3.12.RELEASE",
                  groups: [],
                  source: nil
                }
              ],
              package_manager: "maven"
            )
          ]
        end

        it "updates the version in the POM" do
          expect(updated_pom_file.content).
            to include(
              "<springframework.version>5.0.0.RELEASE</springframework.version>"
            )
        end

        it "doesn't update the formatting of the POM" do
          expect(updated_pom_file.content).
            to include(%(<project xmlns="http://maven.apache.org/POM/4.0.0"\n))
        end
      end
    end
  end
end
