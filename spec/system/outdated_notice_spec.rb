# frozen_string_literal: true

RSpec.describe "Outdated launcher notice" do
  fab!(:user)
  fab!(:admin)
  fab!(:support, :category)
  fab!(:topic) { Fabricate(:post, topic: Fabricate(:topic, category: support)).topic }

  let(:topic_page) { PageObjects::Pages::Topic.new }
  let(:notice) { "#post_1 .post-notice" }

  before do
    enable_current_plugin
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
    DromorcraftCore::KnownVersions.merge!(%w[1.4.24 1.4.21])
    topic.custom_fields["dc_launcher_version"] = "1.4.21"
    topic.save_custom_fields(true)
    sign_in(user)
  end

  # The notice's background, and what --primary-very-low and --danger-low resolve to.
  def backgrounds
    page.evaluate_script(<<~JS)
      (() => {
        const resolve = (value) => {
          const probe = document.createElement("div");
          probe.style.background = value;
          document.body.append(probe);
          const color = getComputedStyle(probe).backgroundColor;
          probe.remove();
          return color;
        };
        return {
          notice: getComputedStyle(document.querySelector("#{notice}")).backgroundColor,
          neutral: resolve("var(--primary-very-low)"),
          danger: resolve("var(--danger-low)"),
        };
      })()
    JS
  end

  it "shows the plugin's notice on the neutral background, without the staff shield" do
    DromorcraftCore::OutdatedNotice.apply(topic)

    topic_page.visit_topic(topic)

    expect(page).to have_css("#{notice} .dromorcraft-outdated-notice", text: "1.4.24 is out")
    expect(page).to have_css("#{notice} .d-icon-circle-info")
    expect(page).to have_no_css("#{notice} .d-icon-user-shield")
    colors = backgrounds
    expect(colors["notice"]).to eq(colors["neutral"])
    expect(colors["notice"]).not_to eq(colors["danger"])
  end

  it "leaves a notice written by staff as core shows it" do
    post = topic.first_post
    post.custom_fields[Post::NOTICE] = {
      "type" => Post.notices[:custom],
      "raw" => "Staff note",
      "cooked" => "<p>Staff note</p>",
      "created_by_user_id" => admin.id,
    }
    post.save_custom_fields(true)

    topic_page.visit_topic(topic)

    expect(page).to have_css(notice, text: "Staff note")
    expect(page).to have_css("#{notice} .d-icon-user-shield")
    expect(page).to have_no_css("#{notice} .dromorcraft-outdated-notice")
    expect(backgrounds["notice"]).to eq(backgrounds["danger"])
  end
end
