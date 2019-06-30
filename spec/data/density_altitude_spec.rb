# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metar::Data::DensityAltitude do
  describe ".parse" do
    subject { described_class.parse("50FT") }

    it "interprets the value as feet" do
      expect(subject.height.to_feet).to eq(50)
    end
  end
end
