# frozen_string_literal: true

RSpec.describe DromorcraftCore::PostExtractor do
  def form(*blocks)
    blocks.map { |label, value| "### #{label}\n#{value}" }.join("\n\n")
  end

  it "reads both versions from a bug report" do
    raw =
      form(
        ["Launcher version", "1.4.24"],
        ["Minecraft version", "1.21.1"],
        ["What happened", "The game closes right after the loading screen."],
        ["Log", "[latest.log|attachment](upload://AbCdEf.log) (12.3 KB)"],
      )

    expect(described_class.call(raw)).to eq(
      "dc_launcher_version" => "1.4.24",
      "dc_mc_version" => "1.21.1",
    )
  end

  it "reads a help request without the optional Minecraft version" do
    raw = form(["Launcher version", "1.4.24"], ["What do you need help with", "Moving worlds"])

    expect(described_class.call(raw)).to eq("dc_launcher_version" => "1.4.24")
  end

  it "accepts Windows line endings" do
    raw = "### Launcher version\r\n1.4.24\r\n\r\n### Minecraft version\r\n1.20.1"

    expect(described_class.call(raw)).to eq(
      "dc_launcher_version" => "1.4.24",
      "dc_mc_version" => "1.20.1",
    )
  end

  it "keeps the first heading when a textarea repeats a label" do
    raw =
      form(
        ["Launcher version", "1.4.24"],
        ["What happened", "Pasted from an old report:\n### Launcher version\n1.0.0"],
      )

    expect(described_class.call(raw)).to eq("dc_launcher_version" => "1.4.24")
  end

  it "returns nothing for a post that wasn't written by the form" do
    expect(described_class.call("My launcher is 1.4.24 and it crashes on 1.21.1")).to eq({})
    expect(described_class.call("## Launcher version\n1.4.24")).to eq({})
    expect(described_class.call("### Launcher version\n\n1.4.24")).to eq({})
    expect(described_class.call("### Launcher version")).to eq({})
    expect(described_class.call("")).to eq({})
    expect(described_class.call(nil)).to eq({})
  end

  it "drops values that are too long or have characters outside the pattern" do
    [
      "1.4.24-beta",
      "1.4.24 <script>",
      "v1.4.24",
      "1.4",
      "1",
      "1.4.24.1.2",
      "1234.4.24",
      "1.4.24​",
      "１.４.２４",
      "9" * 40,
    ].each do |value|
      expect(described_class.call(form(["Launcher version", value]))).to eq({}), value.inspect
    end
  end

  it "accepts the shortest and longest versions the pattern allows" do
    expect(described_class.call(form(["Minecraft version", "1.8"]))).to eq("dc_mc_version" => "1.8")
    expect(described_class.call(form(["Launcher version", "123.123.123.123"]))).to eq(
      "dc_launcher_version" => "123.123.123.123",
    )
  end
end
