# frozen_string_literal: true

module ::DromorcraftCore
  # Reads the versions out of a post written by the support form templates. The composer writes
  # each filled field as "### <label>", a newline and the value, in template order (see the
  # README). Only the first heading with a known label counts: the version fields come first, and
  # a later textarea may contain a line that looks like one of them.
  class PostExtractor
    HEADINGS = {
      "Launcher version" => SupportFields::LAUNCHER_VERSION,
      "Minecraft version" => SupportFields::MC_VERSION,
    }.freeze

    def self.call(raw)
      return {} unless raw.is_a?(String)

      lines = raw.split(/\r?\n/)
      HEADINGS.each_with_object({}) do |(label, field), result|
        index = lines.index { |line| line.rstrip == "### #{label}" }
        next unless index

        value = lines[index + 1].to_s.strip
        result[field] = value if SupportFields.version?(value)
      end
    end
  end
end
