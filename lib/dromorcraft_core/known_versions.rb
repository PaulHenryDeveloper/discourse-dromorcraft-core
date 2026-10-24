# frozen_string_literal: true

module ::DromorcraftCore
  # Launcher versions seen in the releases feed, newest first. The feed only lists the latest
  # releases, so each refresh adds to the list instead of replacing it.
  module KnownVersions
    STORE_KEY = "known_versions"
    MAX = 100

    def self.all
      list = PluginStore.get(PLUGIN_NAME, STORE_KEY)
      list.is_a?(Array) ? list.select { |v| SupportFields.version?(v) } : []
    end

    def self.latest
      all.first
    end

    # Adds versions to the list. An empty or missing list (feed down, feed unreadable) keeps the
    # previous one.
    def self.merge!(versions)
      return all if versions.blank?

      merged = (all | versions).sort_by { |v| Gem::Version.new(v) }.reverse.first(MAX)
      PluginStore.set(PLUGIN_NAME, STORE_KEY, merged)
      merged
    end

    def self.outdated?(version)
      newest = latest
      return false if newest.nil? || !SupportFields.version?(version)

      Gem::Version.new(version) < Gem::Version.new(newest)
    end
  end
end
