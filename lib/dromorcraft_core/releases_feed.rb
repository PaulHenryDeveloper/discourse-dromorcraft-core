# frozen_string_literal: true

module ::DromorcraftCore
  # The public Atom feed of the launcher's releases repository. No token and no setting: the URL
  # is fixed, so nobody can point the forum at another host.
  module ReleasesFeed
    URL = "https://github.com/PaulHenryDeveloper/DromorCraft-releases/releases.atom"
    TIMEOUT = 10
    MAX_BYTES = 1.megabyte

    # Entry ids end in the release tag: tag:github.com,2008:Repository/<id>/v1.4.24.
    TAG = %r{/v([^/]+)\z}

    # Versions in the feed, in feed order. Tags that aren't plain versions (pre-releases,
    # anything odd) are left out.
    def self.parse(xml)
      return [] unless xml.is_a?(String)

      doc = Nokogiri.XML(xml)
      doc.remove_namespaces!
      versions = doc.xpath("/feed/entry/id").map { |id| id.text.strip[TAG, 1] }
      versions.select { |v| SupportFields.version?(v) }.uniq
    end

    # Versions from the live feed, or nil when it can't be read.
    def self.fetch
      response =
        Excon.get(
          URL,
          expects: [200],
          headers: {
            "Accept" => "application/atom+xml",
          },
          connect_timeout: TIMEOUT,
          read_timeout: TIMEOUT,
          write_timeout: TIMEOUT,
        )
      return if response.body.bytesize > MAX_BYTES

      parse(response.body)
    rescue Excon::Error => e
      Rails.logger.warn("dromorcraft-core: releases feed unavailable (#{e.class})")
      nil
    end
  end
end
