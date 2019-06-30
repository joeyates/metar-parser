# frozen_string_literal: true

require "spec_helper"

require "stringio"

RSpec::Matchers.define :have_attribute do |attribute|
  match do |object|
    if !object.respond_to?(attribute)
      false
    else
      object.method(attribute).arity == 0
    end
  end
end

describe Metar::Station do
  context "using structures" do
    let(:response) { double(body: nsd_file) }

    ##
    # NOAA Station list fields:
    #
    # 0    1  2   3          45     6 7      8       9      10      11  12  13
    # PPPP;00;000;Airport P1;;Ppppp;1;11-03S;055-24E;11-03S;055-24E;000;000;P\r
    #
    # 0 - CCCC
    # 1 - ?
    # 2 - ?
    # 3 - name of station
    # 4 - state
    # 5 - country
    # 6 - ?
    # 7 - latitude1
    # 8 - longitude1
    # 9 - latitude2
    # 10 - longitude2
    # 11 - ?
    # 12 - ?
    # 13 - ?
    #
    let(:nsd_file) do
      <<-TEXT.gsub(/^\s{8}/, "")
        PPPP;00;000;Airport P1;;Ppppp;1;11-03S;055-24E;11-03S;055-24E;000;000;P\r
        AAAA;00;000;Airport A1;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P\r
        AAAB;00;000;Airport A2;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P\r
        BBBA;00;000;Airport B1;;Bbbbb;1;11-03S;055-24E;11-03S;055-24E;000;000;P\r
      TEXT
    end

    before do
      allow(Net::HTTP).to receive(:get_response) { response }
    end

    context ".countries" do
      it "lists unique countries in alphabetical order" do
        expect(Metar::Station.countries).to eq(%w(Aaaaa Bbbbb Ppppp))
      end
    end

    context ".all" do
      it "lists all stations" do
        all_ccccs = Metar::Station.all.map(&:cccc)

        expect(all_ccccs).to eq(%w(PPPP AAAA AAAB BBBA))
      end
    end

    context ".find_by_cccc" do
      context "when the station exists" do
        it "returns the matching station" do
          expect(Metar::Station.find_by_cccc("AAAA").name).to eq("Airport A1")
        end
      end

      context "when the station doesn't exist" do
        it "is nil" do
          expect(Metar::Station.find_by_cccc("ZZZZ")).to be_nil
        end
      end
    end

    context ".exist?" do
      it "is true if the cccc exists" do
        expect(Metar::Station.exist?("AAAA")).to be_truthy
      end

      it "is false if the cccc doesn't exist" do
        expect(Metar::Station.exist?("ZZZZ")).to be_falsey
      end
    end

    context ".find_all_by_country" do
      it "lists all stations in a country" do
        aaaaa = Metar::Station.find_all_by_country("Aaaaa")

        expect(aaaaa.map(&:cccc)).to eq(%w(AAAA AAAB))
      end
    end
  end

  context ".to_longitude" do
    it "converts strings to longitude" do
      expect(Metar::Station.to_longitude("055-24E")).to eq(55.4)
    end

    it "returns nil for badly formed strings" do
      expect(Metar::Station.to_longitude("aaa")).to be_nil
    end
  end

  context ".to_latitude" do
    it "converts strings to latitude" do
      expect(Metar::Station.to_latitude("11-03S")).to eq(-11.05)
    end

    it "returns nil for badly formed strings" do
      expect(Metar::Station.to_latitude("aaa")).to be_nil
    end
  end

  let(:cccc) { "DDDD" }
  let(:name) { "Station name" }
  let(:state) { "State" }
  let(:country) { "Country" }
  let(:noaa_raw) do
    cccc +
      ";00;000;" +
      name + ";" +
      state + ";" +
      country + ";1;11-03S;055-24E;11-03S;055-24E;000;000;P"
  end
  let(:noaa_data) do
    {
      cccc: cccc,
      name: name,
      state: state,
      country: country,
      longitude: "055-24E",
      latitude: "11-03S",
      raw: noaa_raw
    }
  end

  context "attributes" do
    subject { Metar::Station.new("DDDD", noaa_data) }
    it { should have_attribute(:cccc)     }
    it { should have_attribute(:code)     }
    it { should have_attribute(:name)     }
    it { should have_attribute(:state)    }
    it { should have_attribute(:country)  }
    it { should have_attribute(:longitude) }
    it { should have_attribute(:latitude) }
    it { should have_attribute(:raw)      }
  end

  context "initialization" do
    it "should fail if cccc is missing" do
      expect do
        Metar::Station.new(nil, {})
      end.to raise_error(RuntimeError, /must not be nil/)
    end

    it "should fail if cccc is empty" do
      expect do
        Metar::Station.new("", {})
      end.to raise_error(RuntimeError, /must not be empty/)
    end

    context "with noaa data" do
      subject { Metar::Station.new("DDDD", noaa_data) }

      specify { expect(subject.cccc).to eq(cccc) }
      specify { expect(subject.name).to eq(name) }
      specify { expect(subject.state).to eq(state) }
      specify { expect(subject.country).to eq(country) }
      specify { expect(subject.longitude).to eq(55.4) }
      specify { expect(subject.latitude).to eq(-11.05) }
      specify { expect(subject.raw).to eq(noaa_raw) }
    end
  end

  context "object navigation" do
    let(:metar) do
      "PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910"
    end
    let(:time) { Date.new(2010, 2, 6) }
    let(:raw) { double(Metar::Raw, metar: metar, time: time) }

    before do
      # TODO: hack - once parser returns station this can be removed
      allow(Metar::Raw::Noaa).to receive(:new) { raw }
      allow(Metar::Station).to receive(:find_by_cccc) { subject }
    end

    subject { described_class.new("DDDD", noaa_data) }

    it ".station should return the Parser" do
      expect(subject.parser).to be_a(Metar::Parser)
    end

    it ".report should return the Report" do
      expect(subject.report).to be_a(Metar::Report)
    end
  end
end
