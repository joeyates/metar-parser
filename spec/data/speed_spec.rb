# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::Speed do
  context ".parse" do
    it "returns nil for nil" do
      speed = described_class.parse(nil)

      expect(speed).to be_nil
    end

    it "parses knots" do
      speed = described_class.parse("5KT")

      expect(speed).to be_a(described_class)
      expect(speed.value).to be_within(0.01).of(2.57)
    end

    it "parses meters per second" do
      speed = described_class.parse("7MPS")

      expect(speed).to be_a(described_class)
      expect(speed.value).to be_within(0.01).of(7.00)
    end

    it "parses kilometers per hour" do
      speed = described_class.parse("14KMH")

      expect(speed).to be_a(described_class)
      expect(speed.value).to be_within(0.01).of(3.89)
    end

    it "treats straight numbers as kilomters per hour" do
      speed = described_class.parse("14")

      expect(speed).to be_a(described_class)
      expect(speed.value).to be_within(0.01).of(3.89)
    end

    it "returns nil for other strings" do
      speed = described_class.parse("")

      expect(speed).to be_nil
    end
  end
end
