# frozen_string_literal: true

require "spec_helper"

describe Metar::Data::VisibilityRemark do
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
