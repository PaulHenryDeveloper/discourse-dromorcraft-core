# frozen_string_literal: true

# name: discourse-dromorcraft-core
# about: Support topics for the DromorCraft launcher: structured launcher, Minecraft, system and loader data from the support form templates.
# version: 0.1.0
# authors: Paul Henry (DromorCraft)
# url: https://github.com/PaulHenryDeveloper/discourse-dromorcraft-core
# required_version: 2026.7.0

enabled_site_setting :dromorcraft_core_enabled

module ::DromorcraftCore
  PLUGIN_NAME = "discourse-dromorcraft-core"
end

require_relative "lib/dromorcraft_core/engine"

after_initialize do
  # Extraction (C-43), known launcher versions (C-44), the support card (C-45) and edit
  # permissions (C-46) come next; see README.md.
end
