# frozen_string_literal: true

require "release_utils/version"

RSpec.describe ReleaseUtils::Version do
  describe ".new" do
    subject(:version) { described_class.new(version_string) }

    context "with a release version" do
      let(:version_string) { "2025.10.1" }

      it do
        is_expected.to have_attributes(major: 2025, minor: 10, patch: 1, pre: nil, revision: nil)
      end
    end

    context "with a development version" do
      let(:version_string) { "2025.10.0-latest" }

      it do
        is_expected.to have_attributes(
          major: 2025,
          minor: 10,
          patch: 0,
          pre: "latest",
          revision: nil,
        )
      end
    end

    context "with a development version with revision" do
      let(:version_string) { "2025.10.0-latest.3" }

      it do
        is_expected.to have_attributes(major: 2025, minor: 10, patch: 0, pre: "latest", revision: 3)
      end
    end

    context "with a malformed version string" do
      let(:version_string) { "not-a-version" }

      it { expect { version }.to raise_error(ArgumentError) }
    end

    it "freezes the instance" do
      expect(described_class.new("2025.10.0")).to be_frozen
    end
  end

  describe "#to_s" do
    subject(:version_string) { described_class.new(input).to_s }

    context "with a release version" do
      let(:input) { "2025.10.1" }

      it { is_expected.to eq("2025.10.1") }
    end

    context "with a development version" do
      let(:input) { "2025.10.0-latest" }

      it { is_expected.to eq("2025.10.0-latest") }
    end

    context "with a development version with revision" do
      let(:input) { "2025.10.0-latest.2" }

      it { is_expected.to eq("2025.10.0-latest.2") }
    end
  end

  describe "#<=>" do
    subject(:version) { described_class.new(version_string) }

    context "with release versions" do
      let(:version_string) { "2025.10.1" }

      it { is_expected.to be > described_class.new("2025.10.0") }
      it { is_expected.to be < described_class.new("2025.11.0") }
      it { is_expected.to eq described_class.new("2025.10.1") }
    end

    context "with a development version" do
      let(:version_string) { "2025.10.0-latest" }

      it { is_expected.to be < described_class.new("2025.10.0") }
    end

    context "with development version revisions" do
      let(:version_string) { "2025.10.0-latest.2" }

      it { is_expected.to be > described_class.new("2025.10.0-latest.1") }
      it { is_expected.to be > described_class.new("2025.10.0-latest") }
    end

    context "with a string argument" do
      let(:version_string) { "2025.10.0" }

      it { is_expected.to be > "2025.9.0" }
    end

    context "with an incompatible type" do
      let(:version_string) { "2025.10.0" }

      it { expect(version <=> 42).to be_nil }
    end
  end

  describe "#development?" do
    subject(:version) { described_class.new(version_string) }

    context "with a development version" do
      let(:version_string) { "2025.10.0-latest" }

      it { is_expected.to be_development }
    end

    context "with a development version with revision" do
      let(:version_string) { "2025.10.0-latest.1" }

      it { is_expected.to be_development }
    end

    context "with a release version" do
      let(:version_string) { "2025.10.0" }

      it { is_expected.not_to be_development }
    end
  end

  describe "#series" do
    subject(:series) { described_class.new(version_string).series }

    context "with a release version" do
      let(:version_string) { "2025.10.3" }

      it { is_expected.to eq("2025.10") }
    end

    context "with a development version with revision" do
      let(:version_string) { "2025.10.0-latest.2" }

      it { is_expected.to eq("2025.10") }
    end
  end

  describe "#branch_name" do
    subject(:branch_name) { described_class.new("2025.10.0-latest").branch_name }

    it { is_expected.to eq("release/2025.10") }
  end

  describe "#tag_name" do
    subject(:tag_name) { described_class.new(version_string).tag_name }

    context "with a release version" do
      let(:version_string) { "2025.10.0" }

      it { is_expected.to eq("v2025.10.0") }
    end

    context "with a development version" do
      let(:version_string) { "2025.10.0-latest" }

      it { is_expected.to eq("v2025.10.0-latest") }
    end

    context "with a development version with revision" do
      let(:version_string) { "2025.10.0-latest.2" }

      it { is_expected.to eq("v2025.10.0-latest.2") }
    end
  end

  describe "#without_revision" do
    subject(:without_revision) { version.without_revision }

    context "with a development version with revision" do
      let(:version) { described_class.new("2025.10.0-latest.2") }

      it { expect(without_revision.to_s).to eq("2025.10.0-latest") }
    end

    context "with a development version without revision" do
      let(:version) { described_class.new("2025.10.0-latest") }

      it { is_expected.to equal(version) }
    end

    context "with a release version" do
      let(:version) { described_class.new("2025.10.0") }

      it { is_expected.to equal(version) }
    end
  end

  describe "#next_development_cycle" do
    subject(:next_version) { described_class.new(version_string).next_development_cycle.to_s }

    context "with a standard development version" do
      let(:version_string) { "2025.10.0-latest" }

      it { is_expected.to eq("2025.11.0-latest") }
    end

    context "with December (year rollover)" do
      let(:version_string) { "2025.12.0-latest" }

      it { is_expected.to eq("2026.1.0-latest") }
    end

    context "with a development version with revision" do
      let(:version_string) { "2025.10.0-latest.2" }

      it { is_expected.to eq("2025.11.0-latest") }
    end
  end

  describe "#next_revision" do
    subject(:next_version) { described_class.new(version_string).next_revision.to_s }

    context "with a plain development version" do
      let(:version_string) { "2025.10.0-latest" }

      it { is_expected.to eq("2025.10.0-latest.1") }
    end

    context "with an existing revision" do
      let(:version_string) { "2025.10.0-latest.2" }

      it { is_expected.to eq("2025.10.0-latest.3") }
    end
  end
end
