# encoding: utf-8
require "spec_helper"

RSpec.describe Metar::VisibilityRemark do
  describe ".parse" do
    subject { described_class.parse("2000W") }

    it "interprets distance in metres" do
      expect(subject.distance.value).to eq(2000)
    end

    it "interprets compass direction" do
      expect(subject.direction).to eq("W")
    end
  end
end

RSpec.describe Metar::DensityAltitude do
  describe ".parse" do
    subject { described_class.parse("50FT") }

    it "interprets the value as feet" do
      expect(subject.height.to_feet).to eq(50)
    end
  end
end
