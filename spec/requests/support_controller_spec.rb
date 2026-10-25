# frozen_string_literal: true

RSpec.describe DromorcraftCore::SupportController do
  fab!(:author) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:other_user) { Fabricate(:user, refresh_auto_groups: true) }
  fab!(:moderator)
  fab!(:admin)
  fab!(:support, :category)
  fab!(:other_category, :category)

  let(:raw) { "### Launcher version\n1.4.21\n\n### What happened\nThe game closes after loading." }
  let(:topic) do
    PostCreator.create!(
      author,
      title: "Game closes after the loading screen",
      raw: raw,
      category: support.id,
    ).topic
  end

  before do
    enable_current_plugin
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
    DromorcraftCore::KnownVersions.merge!(%w[1.4.24 1.4.21])
  end

  def edit(params, target = topic)
    put "/dromorcraft-core/topics/#{target.id}/support.json", params: params
  end

  def fields
    topic.reload.custom_fields.slice(*DromorcraftCore::SupportFields::ALL)
  end

  def notice
    topic.reload.first_post.custom_fields[Post::NOTICE]
  end

  describe "who can edit" do
    it "refuses anonymous users" do
      edit(launcher_version: "1.4.24")

      expect(response.status).to eq(403)
      expect(fields["dc_launcher_version"]).to eq("1.4.21")
    end

    it "refuses another user who can see the topic" do
      sign_in(other_user)

      edit(launcher_version: "1.4.24", os: "linux")

      expect(response.status).to eq(403)
      expect(fields).to eq("dc_launcher_version" => "1.4.21")
    end

    it "lets the author edit" do
      sign_in(author)

      edit(launcher_version: "1.4.24", minecraft_version: "1.21.1", os: "linux", loader: "quilt")

      expect(response.status).to eq(200)
      expect(fields).to eq(
        "dc_launcher_version" => "1.4.24",
        "dc_mc_version" => "1.21.1",
        "dc_os" => "linux",
        "dc_loader" => "quilt",
      )
      expect(response.parsed_body["support"]).to include(
        "launcher_version" => "1.4.24",
        "outdated" => false,
        "can_edit" => true,
      )
      expect(UserHistory.where(custom_type: "dromorcraft_support_edit")).to be_empty
    end

    it "refuses the author once the topic is archived" do
      topic.update!(archived: true)
      sign_in(author)

      edit(launcher_version: "1.4.24")

      expect(response.status).to eq(403)
    end

    it "lets staff edit and logs it" do
      sign_in(moderator)

      edit(launcher_version: "1.4.24")

      expect(response.status).to eq(200)
      expect(fields["dc_launcher_version"]).to eq("1.4.24")
      log = UserHistory.find_by(custom_type: "dromorcraft_support_edit")
      expect(log.acting_user_id).to eq(moderator.id)
      expect(log.topic_id).to eq(topic.id)
      expect(log.details).to include('dc_launcher_version: "1.4.21" -> "1.4.24"')
    end

    it "lets admins edit archived topics" do
      topic.update!(archived: true)
      sign_in(admin)

      edit(os: "windows")

      expect(response.status).to eq(200)
      expect(fields["dc_os"]).to eq("windows")
    end
  end

  describe "what is found" do
    it "is a 404 for topics outside the support categories" do
      outside =
        PostCreator.create!(
          author,
          title: "Not a support topic at all",
          raw: "Just talking about the game.",
          category: other_category.id,
        ).topic
      sign_in(author)

      edit({ os: "windows" }, outside)

      expect(response.status).to eq(404)
    end

    it "is a 404 for topics the user can't see" do
      topic
      support.set_permissions(admins: :full)
      support.save!
      sign_in(other_user)

      edit(os: "windows")

      expect(response.status).to eq(404)
    end

    it "is a 404 while the plugin is disabled" do
      sign_in(author)
      SiteSetting.dromorcraft_core_enabled = false

      edit(os: "windows")

      expect(response.status).to eq(404)
    end
  end

  describe "values" do
    before { sign_in(author) }

    it "changes nothing when one value isn't allowed" do
      edit(launcher_version: "1.4.24", os: "macos")

      expect(response.status).to eq(400)
      expect(fields).to eq("dc_launcher_version" => "1.4.21")
    end

    it "refuses versions that don't match the pattern" do
      edit(minecraft_version: "1.21.1<script>")

      expect(response.status).to eq(400)
      expect(fields).not_to have_key("dc_mc_version")
    end

    it "clears a field sent blank and leaves the others" do
      topic.custom_fields["dc_os"] = "windows"
      topic.save_custom_fields(true)

      edit(os: "")

      expect(response.status).to eq(200)
      expect(fields).to eq("dc_launcher_version" => "1.4.21")
    end
  end

  describe "the outdated notice" do
    before { sign_in(author) }

    it "is removed when the launcher is updated to the latest" do
      expect(notice["raw"]).to include("launcher 1.4.21")

      edit(launcher_version: "1.4.24")

      expect(notice).to be_nil
    end

    it "is rewritten for another old version" do
      topic
      DromorcraftCore::KnownVersions.merge!(%w[1.4.25])

      edit(launcher_version: "1.4.24")

      expect(notice["raw"]).to include("launcher 1.4.24", "1.4.25 is out")
    end

    it "keeps a notice written by staff" do
      post = topic.first_post
      post.custom_fields[Post::NOTICE] = { type: Post.notices[:custom], raw: "Staff note" }
      post.save_custom_fields(true)

      edit(launcher_version: "1.4.24")

      expect(notice["raw"]).to eq("Staff note")
    end
  end

  describe "topic view" do
    { author: true, moderator: true, other_user: false }.each do |name, can_edit|
      it "sends can_edit #{can_edit} to the #{name}" do
        sign_in(public_send(name))

        get "/t/#{topic.id}.json"

        expect(response.parsed_body.dig("dromorcraft_support", "can_edit")).to eq(can_edit)
      end
    end
  end
end
