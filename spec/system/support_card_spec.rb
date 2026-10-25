# frozen_string_literal: true

RSpec.describe "Support card" do
  fab!(:user)
  fab!(:support, :category)
  fab!(:topic) { Fabricate(:post, topic: Fabricate(:topic, category: support)).topic }
  fab!(:other_topic) { Fabricate(:post).topic }

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:card) { ".dromorcraft-support-card" }

  before do
    enable_current_plugin
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
    DromorcraftCore::KnownVersions.merge!(%w[1.4.24 1.4.21])
    {
      "dc_launcher_version" => "1.4.21",
      "dc_mc_version" => "1.21.1",
      "dc_os" => "windows",
      "dc_loader" => "fabric",
    }.each { |name, value| topic.custom_fields[name] = value }
    topic.save_custom_fields(true)
    sign_in(user)
  end

  it "shows the support data above the first post" do
    topic_page.visit_topic(topic)

    expect(page).to have_css("#{card} [data-key='launcher'] dd", text: "1.4.21")
    expect(page).to have_css("#{card} [data-key='minecraft'] dd", text: "1.21.1")
    expect(page).to have_css("#{card} [data-key='system'] dd", text: "Windows")
    expect(page).to have_css("#{card} [data-key='loader'] dd", text: "Fabric")
    expect(page).to have_css(
      "#{card} .dromorcraft-support-card__update[href='https://dromorcraft.com/download/']",
    )
    expect(page).to have_css(
      "#{card} a[href='https://dromorcraft.com/resources/compatibility/']",
    )
  end

  it "puts the card before the first post" do
    topic_page.visit_topic(topic)

    expect(page).to have_css("#post_1")
    expect(page).to have_css(".posts-wrapper #{card}")
    following = page.evaluate_script(<<~JS)
      document.querySelector("#{card}").compareDocumentPosition(
        document.querySelector("#post_1")
      ) & Node.DOCUMENT_POSITION_FOLLOWING
    JS
    expect(following).to be > 0
  end

  it "doesn't show the card on other topics" do
    topic_page.visit_topic(other_topic)

    expect(page).to have_css("#post_1")
    expect(page).to have_no_css(card)
  end

  it "doesn't show the card while the plugin is disabled" do
    SiteSetting.dromorcraft_core_enabled = false

    topic_page.visit_topic(topic)

    expect(page).to have_css("#post_1")
    expect(page).to have_no_css(card)
  end
end
