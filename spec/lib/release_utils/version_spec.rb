# frozen_string_literal: true

require "release_utils/version"

RSpec.describe ReleaseUtils::Version do
  describe ".new" do
    it "parses a release version" do
      version = described_class.new("2025.10.1")
      expect(version.major).to eq(2025)
      expect(version.minor).to eq(10)
      expect(version.patch).to eq(1)
      expect(version.pre).to be_nil
      expect(version.revision).to be_nil
    end

    it "parses a development version" do
      version = described_class.new("2025.10.0-latest")
      expect(version.major).to eq(2025)
      expect(version.minor).to eq(10)
      expect(version.patch).to eq(0)
      expect(version.pre).to eq("latest")
      expect(version.revision).to be_nil
    end

    it "parses a development version with a revision" do
      version = described_class.new("2025.10.0-latest.3")
      expect(version.major).to eq(2025)
      expect(version.minor).to eq(10)
      expect(version.patch).to eq(0)
      expect(version.pre).to eq("latest")
      expect(version.revision).to eq(3)
    end

    it "rejects malformed version strings" do
      expect { described_class.new("not-a-version") }.to raise_error(ArgumentError)
    end

    it "is frozen" do
      expect(described_class.new("2025.10.0")).to be_frozen
    end
  end

  describe "#to_s" do
    it "round-trips a release version" do
      expect(described_class.new("2025.10.1").to_s).to eq("2025.10.1")
    end

    it "round-trips a development version" do
      expect(described_class.new("2025.10.0-latest").to_s).to eq("2025.10.0-latest")
    end

    it "round-trips a development version with revision" do
      expect(described_class.new("2025.10.0-latest.2").to_s).to eq("2025.10.0-latest.2")
    end
  end

  describe "#<=>" do
    it "compares release versions" do
      expect(described_class.new("2025.10.1")).to be > described_class.new("2025.10.0")
      expect(described_class.new("2025.10.0")).to be < described_class.new("2025.11.0")
      expect(described_class.new("2025.10.0")).to eq(described_class.new("2025.10.0"))
    end

    it "orders development versions before their release" do
      expect(described_class.new("2025.10.0-latest")).to be < described_class.new("2025.10.0")
    end

    it "compares development version revisions" do
      expect(described_class.new("2025.10.0-latest.2")).to be >
        described_class.new("2025.10.0-latest.1")
      expect(described_class.new("2025.10.0-latest.1")).to be >
        described_class.new("2025.10.0-latest")
    end

    it "compares against strings" do
      expect(described_class.new("2025.10.0")).to be > "2025.9.0"
    end

    it "returns nil for incompatible types" do
      expect(described_class.new("2025.10.0") <=> 42).to be_nil
    end
  end

  describe "#development?" do
    it "returns true for development versions" do
      expect(described_class.new("2025.10.0-latest")).to be_development
    end

    it "returns true for development versions with revision" do
      expect(described_class.new("2025.10.0-latest.1")).to be_development
    end

    it "returns false for release versions" do
      expect(described_class.new("2025.10.0")).not_to be_development
    end
  end

  describe "#series" do
    it "returns major.minor" do
      expect(described_class.new("2025.10.3").series).to eq("2025.10")
      expect(described_class.new("2025.10.0-latest.2").series).to eq("2025.10")
    end
  end

  describe "#branch_name" do
    it "returns the release branch name" do
      expect(described_class.new("2025.10.0-latest").branch_name).to eq("release/2025.10")
    end
  end

  describe "#tag_name" do
    it "returns the git tag name" do
      expect(described_class.new("2025.10.0").tag_name).to eq("v2025.10.0")
      expect(described_class.new("2025.10.0-latest").tag_name).to eq("v2025.10.0-latest")
      expect(described_class.new("2025.10.0-latest.2").tag_name).to eq("v2025.10.0-latest.2")
    end
  end

  describe "#without_revision" do
    it "strips the revision from a development version" do
      version = described_class.new("2025.10.0-latest.2").without_revision
      expect(version.to_s).to eq("2025.10.0-latest")
    end

    it "returns self when there is no revision" do
      version = described_class.new("2025.10.0-latest")
      expect(version.without_revision).to equal(version)
    end

    it "returns self for release versions" do
      version = described_class.new("2025.10.0")
      expect(version.without_revision).to equal(version)
    end
  end

  describe "#next_development_cycle" do
    it "increments the minor version" do
      expect(described_class.new("2025.10.0-latest").next_development_cycle.to_s).to eq(
        "2025.11.0-latest",
      )
    end

    it "rolls over to next year past December" do
      expect(described_class.new("2025.12.0-latest").next_development_cycle.to_s).to eq(
        "2026.1.0-latest",
      )
    end

    it "drops the revision" do
      expect(described_class.new("2025.10.0-latest.2").next_development_cycle.to_s).to eq(
        "2025.11.0-latest",
      )
    end
  end

  describe "#next_revision" do
    it "adds revision 1 to a plain development version" do
      expect(described_class.new("2025.10.0-latest").next_revision.to_s).to eq("2025.10.0-latest.1")
    end

    it "increments an existing revision" do
      expect(described_class.new("2025.10.0-latest.2").next_revision.to_s).to eq(
        "2025.10.0-latest.3",
      )
    end
  end
end
