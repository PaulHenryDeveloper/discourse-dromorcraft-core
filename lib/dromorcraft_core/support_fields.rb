# frozen_string_literal: true

module ::DromorcraftCore
  # Topic custom fields with the support data, and what each one accepts. Values are checked
  # against an allowlist or a strict pattern before they are stored, never stored as typed.
  module SupportFields
    LAUNCHER_VERSION = "dc_launcher_version"
    MC_VERSION = "dc_mc_version"
    OS = "dc_os"
    LOADER = "dc_loader"
    ALL = [LAUNCHER_VERSION, MC_VERSION, OS, LOADER].freeze

    MAX_LENGTH = 15
    VERSION = /\A[0-9]{1,3}(?:\.[0-9]{1,3}){1,3}\z/

    # Tag groups System and Loader on the forum (structure-setup.rb), one tag of each per topic.
    OS_TAGS = %w[windows linux].freeze
    LOADER_TAGS = %w[vanilla fabric quilt forge neoforge].freeze

    def self.version?(value)
      value.is_a?(String) && value.length <= MAX_LENGTH && value.match?(VERSION)
    end
  end
end
