# frozen_string_literal: true

require "dependabot/metadata_finders/c_sharp/nuget"
require_relative "../shared_examples_for_metadata_finders"

RSpec.describe Dependabot::MetadataFinders::CSharp::Nuget do
  it_behaves_like "a dependency metadata finder"
end
