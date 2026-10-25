# frozen_string_literal: true

module ::DromorcraftCore
  # What the support card above the first post shows: the stored support fields, whether the
  # launcher is outdated and which of the site's resource pages to suggest. Values are checked
  # again here, so a field changed by hand never reaches the page as typed.
  module SupportCard
    # Pages under https://dromorcraft.com/resources/ (src/config/docs.ts on the site).
    ALWAYS = %w[errors java].freeze
    MODDED_LOADERS = (SupportFields::LOADER_TAGS - %w[vanilla]).freeze

    def self.for(topic)
      return unless TopicExtractor.in_scope?(topic)

      fields = topic.custom_fields
      launcher = version(fields[SupportFields::LAUNCHER_VERSION])
      minecraft = version(fields[SupportFields::MC_VERSION])
      os = allowed(fields[SupportFields::OS], SupportFields::OS_TAGS)
      loader = allowed(fields[SupportFields::LOADER], SupportFields::LOADER_TAGS)
      return if [launcher, minecraft, os, loader].all?(&:nil?)

      outdated = KnownVersions.outdated?(launcher)
      {
        launcher_version: launcher,
        minecraft_version: minecraft,
        os: os,
        loader: loader,
        latest_version: outdated ? KnownVersions.latest : nil,
        outdated: outdated,
        resources: resources(outdated: outdated, loader: loader),
      }
    end

    def self.resources(outdated:, loader:)
      list = []
      list << "updates" if outdated
      list.concat(ALWAYS)
      list << "compatibility" if MODDED_LOADERS.include?(loader)
      list
    end

    def self.version(value)
      value if SupportFields.version?(value)
    end

    def self.allowed(value, list)
      value if list.include?(value)
    end
  end
end
