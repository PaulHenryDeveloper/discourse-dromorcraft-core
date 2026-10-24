# frozen_string_literal: true

module ::DromorcraftCore
  # Fills the support custom fields of a new topic: versions from the first post, system and
  # loader from its tags. Only regular topics in the categories of the
  # dromorcraft_core_support_categories setting are read.
  class TopicExtractor
    TAG_FIELDS = {
      SupportFields::OS => SupportFields::OS_TAGS,
      SupportFields::LOADER => SupportFields::LOADER_TAGS,
    }.freeze

    def self.in_scope?(topic)
      return false unless topic&.regular?

      ids = SiteSetting.dromorcraft_core_support_categories.split("|").map(&:to_i)
      ids.include?(topic.category_id)
    end

    def self.call(topic)
      fields = PostExtractor.call(topic.first_post&.raw)
      tags = topic.tags.map(&:name)
      TAG_FIELDS.each do |field, allowed|
        found = tags & allowed
        fields[field] = found.first if found.size == 1
      end
      fields
    end

    # True when the topic is in scope and something was stored.
    def self.store(topic)
      return false unless in_scope?(topic)

      fields = call(topic)
      return false if fields.empty?

      fields.each { |name, value| topic.custom_fields[name] = value }
      topic.save_custom_fields(true)
      true
    end
  end
end
