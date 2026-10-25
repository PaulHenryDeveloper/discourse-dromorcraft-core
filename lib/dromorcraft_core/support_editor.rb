# frozen_string_literal: true

module ::DromorcraftCore
  # Changes the support fields of a topic. Who may call it is the guardian's job
  # (can_edit_dromorcraft_support?); this only checks the values.
  module SupportEditor
    FIELDS = {
      "launcher_version" => SupportFields::LAUNCHER_VERSION,
      "minecraft_version" => SupportFields::MC_VERSION,
      "os" => SupportFields::OS,
      "loader" => SupportFields::LOADER,
    }.freeze

    # Sets the given values; a blank value clears the field. Every value is checked before
    # anything is saved, so one bad value changes nothing. Returns { field => [old, new] }.
    def self.call(topic, values)
      wanted = normalize(values)
      changes = {}
      wanted.each do |field, value|
        old = topic.custom_fields[field]
        next if old == value

        changes[field] = [old, value]
        if value
          topic.custom_fields[field] = value
        else
          topic.custom_fields.delete(field)
        end
      end
      topic.save_custom_fields(true) if changes.present?
      changes
    end

    def self.normalize(values)
      wanted = {}
      values.each do |key, value|
        field = FIELDS[key.to_s]
        next if field.nil?
        raise Discourse::InvalidParameters.new(key) if !value.nil? && !value.is_a?(String)

        value = value.to_s.strip.presence
        raise Discourse::InvalidParameters.new(key) if value && !valid?(field, value)

        wanted[field] = value
      end
      wanted
    end

    def self.valid?(field, value)
      case field
      when SupportFields::OS
        SupportFields::OS_TAGS.include?(value)
      when SupportFields::LOADER
        SupportFields::LOADER_TAGS.include?(value)
      else
        SupportFields.version?(value)
      end
    end
  end
end
