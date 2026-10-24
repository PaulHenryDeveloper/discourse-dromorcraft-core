# frozen_string_literal: true

RSpec.describe Jobs::DromorcraftCore::RefreshKnownVersions do
  let(:url) { DromorcraftCore::ReleasesFeed::URL }
  let(:recorded) { File.read(File.expand_path("../fixtures/releases.atom", __dir__)) }

  before { enable_current_plugin }

  def known
    DromorcraftCore::KnownVersions.all
  end

  it "stores the versions of the feed" do
    stub_request(:get, url).to_return(status: 200, body: recorded)

    described_class.new.execute

    expect(known.first(3)).to eq(%w[1.4.24 1.4.22 1.4.21])
    expect(known.last).to eq("1.4.9")
  end

  it "keeps older versions that left the feed" do
    DromorcraftCore::KnownVersions.merge!(%w[1.4.5])
    stub_request(:get, url).to_return(status: 200, body: recorded)

    described_class.new.execute

    expect(known.first).to eq("1.4.24")
    expect(known.last).to eq("1.4.5")
  end

  context "when the feed can't be read" do
    before { DromorcraftCore::KnownVersions.merge!(%w[1.4.22 1.4.21]) }

    it "keeps the previous list on an error status" do
      stub_request(:get, url).to_return(status: 500, body: "")

      described_class.new.execute

      expect(known).to eq(%w[1.4.22 1.4.21])
    end

    it "keeps the previous list on a timeout" do
      stub_request(:get, url).to_timeout

      described_class.new.execute

      expect(known).to eq(%w[1.4.22 1.4.21])
    end

    it "keeps the previous list when the answer isn't a feed" do
      stub_request(:get, url).to_return(status: 200, body: "<html>Unicorn!</html>")

      described_class.new.execute

      expect(known).to eq(%w[1.4.22 1.4.21])
    end
  end

  it "doesn't call the feed while the plugin is disabled" do
    SiteSetting.dromorcraft_core_enabled = false

    described_class.new.execute

    expect(a_request(:get, url)).not_to have_been_made
    expect(known).to eq([])
  end
end
