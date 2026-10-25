# frozen_string_literal: true

class DromorcraftCore::SupportController < ::ApplicationController
  requires_plugin DromorcraftCore::PLUGIN_NAME

  before_action :ensure_logged_in

  # PUT /dromorcraft-core/topics/:topic_id/support
  # Only the topic's author and staff may change the fields (403 for anyone else who can see
  # the topic). Topics outside the support categories, or that the user can't see, are a 404.
  def update
    topic = Topic.find_by(id: params.require(:topic_id))
    raise Discourse::NotFound if topic.nil? || !guardian.can_see_topic?(topic)
    raise Discourse::NotFound if !DromorcraftCore::TopicExtractor.in_scope?(topic)
    raise Discourse::InvalidAccess if !guardian.can_edit_dromorcraft_support?(topic)

    if !current_user.staff?
      RateLimiter.new(current_user, "dromorcraft-support-edit", 10, 1.minute).performed!
    end

    keys = DromorcraftCore::SupportEditor::FIELDS.keys
    values = params.slice(*keys).permit(*keys).to_h
    changes = DromorcraftCore::SupportEditor.call(topic, values)

    if changes.key?(DromorcraftCore::SupportFields::LAUNCHER_VERSION)
      DromorcraftCore::OutdatedNotice.refresh(topic)
    end
    log_staff_edit(topic, changes) if changes.present? && topic.user_id != current_user.id

    support = DromorcraftCore::SupportCard.for(topic.reload)
    support = support.merge(can_edit: true) if support
    render json: { support: support }
  end

  private

  def log_staff_edit(topic, changes)
    details = changes.map { |field, (old, new)| "#{field}: #{old.inspect} -> #{new.inspect}" }
    StaffActionLogger.new(current_user).log_custom(
      "dromorcraft_support_edit",
      topic_id: topic.id,
      changes: details.join(", "),
    )
  end
end
