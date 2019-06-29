# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Temperature do
  context ".parse" do
    it "understands numbers" do
      t = described_class.parse("5")

      expect(t.value).to be_within(0.01).of(5.0)
    end

    it "treats an M-prefix as a negative indicator" do
      t = described_class.parse("M5")

      expect(t.value).to be_within(0.01).of(-5.0)
    end

    it "returns nil for other values" do
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse("aaa")).to be_nil
    end
  end

  context "#to_s" do
    it "abbreviates the units" do
      t = described_class.new(5)

      expect(t.to_s).to eq("5°C")
    end

    it "rounds to the nearest degree" do
      expect(described_class.new(5.1).to_s).to eq("5°C")
      expect(described_class.new(5.5).to_s).to eq("6°C")
    end
  end
end
