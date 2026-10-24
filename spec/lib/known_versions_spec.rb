# frozen_string_literal: true

RSpec.describe DromorcraftCore::KnownVersions do
  it "starts empty" do
    expect(described_class.all).to eq([])
    expect(described_class.latest).to be_nil
  end

  it "sorts versions by number, not as text" do
    described_class.merge!(%w[1.4.9 1.4.10 1.4.24 1.4.100])

    expect(described_class.all).to eq(%w[1.4.100 1.4.24 1.4.10 1.4.9])
    expect(described_class.latest).to eq("1.4.100")
  end

  it "adds to the previous list instead of replacing it" do
    described_class.merge!(%w[1.4.5 1.4.9])
    described_class.merge!(%w[1.4.24 1.4.9])

    expect(described_class.all).to eq(%w[1.4.24 1.4.9 1.4.5])
  end

  it "keeps the previous list when there is nothing to add" do
    described_class.merge!(%w[1.4.24])

    expect(described_class.merge!(nil)).to eq(%w[1.4.24])
    expect(described_class.merge!([])).to eq(%w[1.4.24])
    expect(described_class.all).to eq(%w[1.4.24])
  end

  it "keeps only the newest versions" do
    described_class.merge!((1..120).map { |n| "1.#{n}" })

    expect(described_class.all.size).to eq(described_class::MAX)
    expect(described_class.all.last).to eq("1.21")
  end

  it "ignores stored values that aren't versions" do
    PluginStore.set(DromorcraftCore::PLUGIN_NAME, described_class::STORE_KEY, ["1.4.24", "<b>", 3])

    expect(described_class.all).to eq(%w[1.4.24])
  end

  describe ".outdated?" do
    before { described_class.merge!(%w[1.4.24 1.4.10]) }

    it "is true for versions older than the latest" do
      expect(described_class.outdated?("1.4.22")).to eq(true)
      expect(described_class.outdated?("1.4.9")).to eq(true)
    end

    it "is false for the latest, newer or invalid versions" do
      expect(described_class.outdated?("1.4.24")).to eq(false)
      expect(described_class.outdated?("1.5.0")).to eq(false)
      expect(described_class.outdated?("1.4.22-beta")).to eq(false)
      expect(described_class.outdated?(nil)).to eq(false)
    end

    it "is false while no version is known" do
      PluginStore.remove(DromorcraftCore::PLUGIN_NAME, described_class::STORE_KEY)

      expect(described_class.outdated?("1.0")).to eq(false)
    end
  end
end
