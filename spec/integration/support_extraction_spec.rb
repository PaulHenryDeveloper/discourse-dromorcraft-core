# frozen_string_literal: true

RSpec.describe "Support extraction on topic creation" do
  fab!(:admin)
  fab!(:support, :category)
  fab!(:other_category, :category)
  fab!(:windows) { Fabricate(:tag, name: "windows") }
  fab!(:linux) { Fabricate(:tag, name: "linux") }
  fab!(:fabric) { Fabricate(:tag, name: "fabric") }

  let(:raw) { <<~MD.strip }
    ### Launcher version
    1.4.24

    ### Minecraft version
    1.21.1

    ### What happened
    The game closes right after the loading screen.
  MD

  before do
    enable_current_plugin
    SiteSetting.tagging_enabled = true
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
  end

  def create_topic(category: support, tags: %w[windows fabric], body: raw)
    PostCreator.create!(
      admin,
      title: "Game closes after the loading screen",
      raw: body,
      category: category.id,
      tags: tags,
    ).topic
  end

  def support_fields(topic)
    topic.reload.custom_fields.slice(*DromorcraftCore::SupportFields::ALL)
  end

  it "stores the versions from the post and the system and loader from the tags" do
    expect(support_fields(create_topic)).to eq(
      "dc_launcher_version" => "1.4.24",
      "dc_mc_version" => "1.21.1",
      "dc_os" => "windows",
      "dc_loader" => "fabric",
    )
  end

  it "stores only the tags when the post wasn't written by the form" do
    topic = create_topic(body: "Something is broken, the launcher closes when I press play.")

    expect(support_fields(topic)).to eq("dc_os" => "windows", "dc_loader" => "fabric")
  end

  it "skips the system when the topic has more than one system tag" do
    topic = create_topic(tags: %w[windows linux fabric])

    expect(support_fields(topic)).not_to have_key("dc_os")
  end

  it "ignores categories outside the setting" do
    expect(support_fields(create_topic(category: other_category))).to eq({})
  end

  it "ignores personal messages" do
    post =
      PostCreator.create!(
        admin,
        title: "Game closes after the loading screen",
        raw: raw,
        archetype: Archetype.private_message,
        target_usernames: Fabricate(:user).username,
      )

    expect(support_fields(post.topic)).to eq({})
  end

  it "does nothing while the plugin is disabled" do
    SiteSetting.dromorcraft_core_enabled = false

    expect(support_fields(create_topic)).to eq({})
  end

  it "still creates the topic when extraction fails" do
    DromorcraftCore::PostExtractor.stubs(:call).raises(StandardError, "boom")

    topic = create_topic

    expect(topic).to be_persisted
    expect(support_fields(topic)).to eq({})
  end
end
