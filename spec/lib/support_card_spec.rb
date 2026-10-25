# frozen_string_literal: true

RSpec.describe DromorcraftCore::SupportCard do
  fab!(:support, :category)
  fab!(:topic) { Fabricate(:topic, category: support) }

  before do
    SiteSetting.dromorcraft_core_support_categories = support.id.to_s
    DromorcraftCore::KnownVersions.merge!(%w[1.4.24 1.4.21])
  end

  def with_fields(fields)
    fields.each { |name, value| topic.custom_fields[name] = value }
    topic.save_custom_fields(true)
    topic.reload
  end

  it "returns the stored fields with the resources" do
    with_fields(
      "dc_launcher_version" => "1.4.24",
      "dc_mc_version" => "1.21.1",
      "dc_os" => "windows",
      "dc_loader" => "fabric",
    )

    expect(described_class.for(topic)).to eq(
      launcher_version: "1.4.24",
      minecraft_version: "1.21.1",
      os: "windows",
      loader: "fabric",
      latest_version: nil,
      outdated: false,
      resources: %w[errors java compatibility],
    )
  end

  it "flags an outdated launcher and suggests the updates page first" do
    with_fields("dc_launcher_version" => "1.4.21", "dc_loader" => "vanilla")

    card = described_class.for(topic)

    expect(card).to include(outdated: true, latest_version: "1.4.24")
    expect(card[:resources]).to eq(%w[updates errors java])
  end

  it "drops values that aren't allowed" do
    with_fields(
      "dc_launcher_version" => "1.4.24<script>",
      "dc_os" => "macos",
      "dc_loader" => "fabric",
    )

    expect(described_class.for(topic)).to include(launcher_version: nil, os: nil, loader: "fabric")
  end

  it "returns nothing without support data or outside the support categories" do
    expect(described_class.for(topic)).to be_nil

    other = Fabricate(:topic)
    other.custom_fields["dc_os"] = "windows"
    other.save_custom_fields(true)
    expect(described_class.for(other.reload)).to be_nil
  end
end
