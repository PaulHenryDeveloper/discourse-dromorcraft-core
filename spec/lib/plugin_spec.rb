# frozen_string_literal: true

RSpec.describe DromorcraftCore do
  it "is off until an admin turns it on" do
    expect(SiteSetting.dromorcraft_core_enabled).to eq(false)
  end

  it "loads the engine" do
    expect(DromorcraftCore::Engine.engine_name).to eq(DromorcraftCore::PLUGIN_NAME)
  end
end
