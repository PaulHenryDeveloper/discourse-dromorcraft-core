# frozen_string_literal: true

RSpec.describe DromorcraftCore::ReleasesFeed do
  # The real feed, recorded on 2026-10-24.
  let(:recorded) { File.read(File.expand_path("../fixtures/releases.atom", __dir__)) }
  let(:recorded_versions) do
    %w[1.4.24 1.4.22 1.4.21 1.4.20 1.4.14 1.4.13 1.4.12 1.4.11 1.4.10 1.4.9]
  end

  def feed(*ids)
    entries = ids.map { |id| "<entry><id>tag:github.com,2008:Repository/1/#{id}</id></entry>" }
    %(<?xml version="1.0"?><feed xmlns="http://www.w3.org/2005/Atom">#{entries.join}</feed>)
  end

  describe ".parse" do
    it "reads the versions of the recorded feed in feed order" do
      expect(described_class.parse(recorded)).to eq(recorded_versions)
    end

    it "leaves out tags that aren't plain versions" do
      xml =
        feed(
          "v1.5.0-beta",
          "v1.5.0",
          "vnext",
          "1.4.30",
          "v1.4.24&lt;script&gt;",
          "v1.5.0",
          "v1.4.24.1.2",
        )

      expect(described_class.parse(xml)).to eq(%w[1.5.0])
    end

    it "returns nothing for a page that isn't a feed" do
      expect(described_class.parse("<html><body>Unicorn!</body></html>")).to eq([])
      expect(described_class.parse("not xml at all")).to eq([])
      expect(described_class.parse(nil)).to eq([])
    end
  end

  describe ".fetch" do
    it "reads the live feed" do
      stub_request(:get, described_class::URL).to_return(status: 200, body: recorded)

      expect(described_class.fetch).to eq(recorded_versions)
    end

    it "returns nil when the feed answers with an error" do
      stub_request(:get, described_class::URL).to_return(status: 503, body: "")

      expect(described_class.fetch).to be_nil
    end

    it "returns nil when the feed times out" do
      stub_request(:get, described_class::URL).to_timeout

      expect(described_class.fetch).to be_nil
    end

    it "returns nil for an oversized answer" do
      body = "a" * (described_class::MAX_BYTES + 1)
      stub_request(:get, described_class::URL).to_return(status: 200, body: body)

      expect(described_class.fetch).to be_nil
    end
  end
end
