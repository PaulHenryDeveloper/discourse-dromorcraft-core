# frozen_string_literal: true

DromorcraftCore::Engine.routes.draw { put "/topics/:topic_id/support" => "support#update" }

Discourse::Application.routes.draw { mount DromorcraftCore::Engine, at: "dromorcraft-core" }
