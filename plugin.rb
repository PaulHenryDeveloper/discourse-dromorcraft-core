# frozen_string_literal: true

# name: discourse-dromorcraft-core
# about: Support topics for the DromorCraft launcher: structured launcher, Minecraft, system and loader data from the support form templates.
# version: 0.2.0
# authors: Paul Henry (DromorCraft)
# url: https://github.com/PaulHenryDeveloper/discourse-dromorcraft-core
# required_version: 2026.7.0

enabled_site_setting :dromorcraft_core_enabled

module ::DromorcraftCore
  PLUGIN_NAME = "discourse-dromorcraft-core"
end

require_relative "lib/dromorcraft_core/engine"

after_initialize do
  DromorcraftCore::SupportFields::ALL.each do |field|
    register_topic_custom_field_type(
      field,
      :string,
      max_length: DromorcraftCore::SupportFields::MAX_LENGTH,
    )
  end

  # Extraction never gets in the way of posting: a failure is logged and the topic goes on.
  on(:topic_created) do |topic, _opts, _user|
    next unless SiteSetting.dromorcraft_core_enabled

    begin
      DromorcraftCore::TopicExtractor.store(topic)
    rescue StandardError => e
      Discourse.warn_exception(
        e,
        message: "dromorcraft-core: support extraction failed for topic #{topic&.id}",
      )
    end
  end
end
