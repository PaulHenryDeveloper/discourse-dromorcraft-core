# frozen_string_literal: true

RSpec.describe "Outdated launcher notice" do
  fab!(:user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:support, :category)
  fab!(:other_category, :category)

  before do
    enable_current_plugin
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
    DromorcraftCore::KnownVersions.merge!(%w[1.4.24 1.4.22 1.4.21])
  end

  def create_topic(version: "1.4.21", category: support)
    raw = "### Launcher version\n#{version}\n\n### What happened\nThe game closes after loading."
    PostCreator.create!(
      user,
      title: "Game closes after loading on #{version}",
      raw: raw,
      category: category.id,
    ).topic
  end

  def notice(topic)
    topic.reload.first_post.custom_fields[Post::NOTICE]
  end

  def custom_notice(topic)
    found = notice(topic)
    found if found.is_a?(Hash) && found["type"] == Post.notices[:custom]
  end

  # A topic outside the support categories with a notice already on its first post, so the
  # notice can be applied by hand.
  def topic_with_notice(existing)
    topic = create_topic(category: other_category)
    post = topic.first_post
    post.custom_fields[Post::NOTICE] = existing
    post.save_custom_fields(true)
    topic.custom_fields[DromorcraftCore::SupportFields::LAUNCHER_VERSION] = "1.4.21"
    topic.save_custom_fields(true)
    topic.reload
  end

  it "points a topic on an old launcher to the download page" do
    found = custom_notice(create_topic(version: "1.4.21"))

    expect(found["raw"]).to include("launcher 1.4.21", "1.4.24 is out")
    expect(found["cooked"]).to include('href="https://dromorcraft.com/download/"')
    expect(found["created_by_user_id"]).to eq(Discourse.system_user.id)
  end

  it "replaces the automatic first-post notice" do
    topic = topic_with_notice({ type: Post.notices[:new_user] })

    DromorcraftCore::OutdatedNotice.apply(topic)

    expect(custom_notice(topic)["raw"]).to include("launcher 1.4.21")
  end

  it "leaves topics on the latest or a newer launcher alone" do
    expect(custom_notice(create_topic(version: "1.4.24"))).to be_nil
    expect(custom_notice(create_topic(version: "1.5.0"))).to be_nil
  end

  it "does nothing while no version is known" do
    PluginStore.remove(DromorcraftCore::PLUGIN_NAME, DromorcraftCore::KnownVersions::STORE_KEY)

    expect(custom_notice(create_topic)).to be_nil
  end

  it "does nothing outside the support categories" do
    expect(custom_notice(create_topic(category: other_category))).to be_nil
  end

  it "does nothing when the notice is turned off" do
    SiteSetting.dromorcraft_core_outdated_notice = false

    expect(custom_notice(create_topic)).to be_nil
  end

  it "keeps a notice written by staff" do
    topic = topic_with_notice({ type: Post.notices[:custom], raw: "Staff note" })

    DromorcraftCore::OutdatedNotice.apply(topic)

    expect(notice(topic)["raw"]).to eq("Staff note")
  end
end
