# frozen_string_literal: true

module ::DromorcraftCore
  # Puts a notice above the first post of a support topic reported on an old launcher, with a
  # link to the download page. A post notice instead of a reply: it doesn't bump the topic or
  # count as an answer, so "unanswered" and the stalled-topic reminder still work.
  module OutdatedNotice
    DOWNLOAD_URL = "https://dromorcraft.com/download/"
    # Marks the notices this plugin wrote, so they can be updated or removed later.
    MARKER = "dromorcraft"

    def self.apply(topic)
      return unless SiteSetting.dromorcraft_core_outdated_notice

      version = topic.custom_fields[SupportFields::LAUNCHER_VERSION]
      return unless KnownVersions.outdated?(version)

      post = topic.first_post
      return if post.nil?

      # A notice written by staff wins; ours and the automatic first-post notices don't.
      current = post.custom_fields[Post::NOTICE]
      return if current.is_a?(Hash) && current["type"] == Post.notices[:custom] && !ours?(current)

      raw =
        I18n.t(
          "dromorcraft_core.outdated_notice",
          locale: :en,
          version: version,
          latest: KnownVersions.latest,
          url: DOWNLOAD_URL,
        )
      post.custom_fields[Post::NOTICE] = {
        "type" => Post.notices[:custom],
        "raw" => raw,
        "cooked" => PrettyText.cook(raw, features: { onebox: false }),
        "created_by_user_id" => Discourse.system_user.id,
        MARKER => "outdated",
      }
      post.save_custom_fields(true)
    end

    # After the launcher version is edited: rewrites our notice for the new version, or removes
    # it when the version is no longer outdated. Notices written by staff are left alone.
    def self.refresh(topic)
      version = topic.custom_fields[SupportFields::LAUNCHER_VERSION]
      return apply(topic) if KnownVersions.outdated?(version)

      post = topic.first_post
      return if post.nil? || !ours?(post.custom_fields[Post::NOTICE])

      post.custom_fields.delete(Post::NOTICE)
      post.save_custom_fields(true)
    end

    def self.ours?(notice)
      notice.is_a?(Hash) && notice[MARKER] == "outdated"
    end
  end
end
