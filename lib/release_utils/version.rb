# frozen_string_literal: true

module ReleaseUtils
  class Version
    include Comparable

    attr_reader :major, :minor, :patch, :pre, :revision

    def initialize(version_string)
      @gem_version = Gem::Version.new(version_string)

      segments = @gem_version.segments
      @major = segments[0]
      @minor = segments[1] || 1
      @patch = segments[2] || 0

      if @gem_version.prerelease?
        pre_segments = segments.drop(3).drop_while { |s| s == "pre" }
        @pre = pre_segments.first
        @revision = pre_segments[1] if pre_segments.length > 1
      end

      freeze
    end

    class << self
      def current
        version_string = File.read("lib/version.rb")[/STRING = "(.*)"/, 1]
        raise "Unable to parse current version from lib/version.rb" if version_string.nil?
        new(version_string)
      end

      def next
        target = new("#{Time.current.strftime("%Y.%-m")}.0-latest")
        return target if target > current
        current.next_development_cycle
      end
    end

    def <=>(other)
      other = self.class.new(other) if other.is_a?(String)
      return nil unless other.is_a?(self.class)
      gem_version <=> other.gem_version
    end

    def same_development_cycle?(other)
      development? && other.development? && without_revision == other.without_revision
    end

    def same_series?(other)
      series == other.series
    end

    def development?
      pre == "latest"
    end

    def series
      "#{major}.#{minor}"
    end

    def branch_name
      "release/#{series}"
    end

    def tag_name
      "v#{self}"
    end

    def without_revision
      return self if revision.nil?
      self.class.new("#{major}.#{minor}.#{patch}-#{pre}")
    end

    def next_development_cycle
      new_major = major
      new_minor = minor + 1

      if new_minor > 12
        new_major += 1
        new_minor = 1
      end

      self.class.new("#{new_major}.#{new_minor}.0-latest")
    end

    def bump_revision
      self.class.new("#{major}.#{minor}.#{patch}-latest.#{(revision || 0) + 1}")
    end

    def to_s
      s = +"#{major}.#{minor}.#{patch}"
      s << "-#{pre}" if pre
      s << ".#{revision}" if revision
      s.freeze
    end

    def inspect
      "#<#{self.class} #{self}>"
    end

    protected

    attr_reader :gem_version
  end
end
