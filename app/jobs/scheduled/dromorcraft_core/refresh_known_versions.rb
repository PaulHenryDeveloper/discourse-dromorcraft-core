# frozen_string_literal: true

module Jobs
  module DromorcraftCore
    class RefreshKnownVersions < ::Jobs::Scheduled
      every 1.hour

      def execute(_args = nil)
        return unless SiteSetting.dromorcraft_core_enabled

        ::DromorcraftCore::KnownVersions.merge!(::DromorcraftCore::ReleasesFeed.fetch)
      end
    end
  end
end
