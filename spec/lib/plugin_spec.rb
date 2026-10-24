# frozen_string_literal: true

RSpec.describe DromorcraftCore do
  it "is off until an admin turns it on" do
    expect(SiteSetting.dromorcraft_core_enabled).to eq(false)
  end

  it "is registered as a plugin" do
    expect(Discourse.plugins.map(&:name)).to include(DromorcraftCore::PLUGIN_NAME)
  end
end
