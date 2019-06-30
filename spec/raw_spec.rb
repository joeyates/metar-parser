# frozen_string_literal: true

require 'spec_helper'

require 'net/ftp'
require 'time'
require 'timecop'

module MetarRawTestHelper
  def raw_metar
    "ESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55"
  end
end

describe Metar::Raw::Data do
  include MetarRawTestHelper

  context 'initialization' do
    let(:time) { Time.parse('2012-07-29 16:35') }

    subject { described_class.new(raw_metar, time) }

    it "accepts a METAR string" do
      expect(subject.metar).to eq(raw_metar)
    end

    it "accepts a reading time" do
      expect(subject.time).to eq(time)
    end

    context "when called without a time parameter" do
      it "warns that the usage is deprecated" do
        expect { described_class.new(raw_metar) }.
          to output(/deprecated/).to_stderr
      end
    end
  end
end

describe Metar::Raw::Metar do
  context "time" do
    let(:call_time) { Time.parse("2016-04-01 16:35") }
    let(:raw_metar) { "OPPS 312359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011" }

    subject { described_class.new(raw_metar) }

    before { Timecop.freeze(call_time) }
    after { Timecop.return }

    it "is the last day with the day of month from the METAR datetime" do
      expect(subject.time.year).to eq(2016)
      expect(subject.time.month).to eq(3)
      expect(subject.time.day).to eq(31)
    end

    context "when the current day of month " \
            "is greater than the METAR's day of month" do
      let(:call_time) { Time.parse("2016-04-11 16:35") }
      let(:raw_metar) do
        "OPPS 092359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011"
      end

      it "uses the date from the current month" do
        expect(subject.time.year).to eq(2016)
        expect(subject.time.month).to eq(4)
        expect(subject.time.day).to eq(9)
      end
    end

    context "when the previous month did not have the day of the month" do
      let(:call_time) { Time.parse("2016-05-01 16:35") }

      it "skips back to a previous month" do
        expect(subject.time.year).to eq(2016)
        expect(subject.time.month).to eq(3)
        expect(subject.time.day).to eq(31)
      end
    end

    context "when the datetime doesn't have 6 numerals" do
      let(:raw_metar) { "OPPS 3123Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011" }

      it "throws an error" do
        expect { subject.time }.to raise_error(RuntimeError, /6 digit/)
      end
    end

    context "when the day of month in the datetime is > 31" do
      let(:raw_metar) do
        "OPPS 332359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011"
      end

      it "throws an error" do
        expect { subject.time }.to raise_error(RuntimeError, /at most 31/)
      end
    end

    context "when the day of month in the datetime is 0" do
      let(:raw_metar) do
        "OPPS 002359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011"
      end

      it "throws an error" do
        expect { subject.time }.to raise_error(RuntimeError, /greater than 0/)
      end
    end
  end
end

describe Metar::Raw::Noaa do
  include MetarRawTestHelper

  let(:cccc) { "ESSB" }
  let(:ftp) do
    double(
      Net::FTP,
      chdir: nil,
      close: nil,
      login: nil,
      :passive= => nil,
      retrbinary: nil
    )
  end

  before do
    allow(Net::FTP).to receive(:new) { ftp }
  end

  context '.fetch' do
    before do
      allow(ftp).
        to receive(:retrbinary).and_yield("chunk 1\n").and_yield("chunk 2\n")
    end

    it 'downloads the raw report' do
      Metar::Raw::Noaa.fetch('the_cccc')

      expect(ftp).
        to have_received(:retrbinary).
        with('RETR the_cccc.TXT', kind_of(Integer))
    end

    it 'returns the data' do
      raw = Metar::Raw::Noaa.fetch('the_cccc')

      expect(raw).to eq("chunk 1\nchunk 2\n")
    end

    it 'closes the connection' do
      Metar::Raw::Noaa.fetch('the_cccc')

      expect(ftp).to have_received(:close)
    end

    context 'if retrieval fails once' do
      before do
        @attempt = 0

        allow(ftp).to receive(:retrbinary) do |_args, &block|
          @attempt += 1
          raise Net::FTPTempError if @attempt == 1

          block.call "chunk 1\n"
          block.call "chunk 2\n"
        end
      end

      it 'retries' do
        raw = Metar::Raw::Noaa.fetch('the_cccc')

        expect(raw).to eq("chunk 1\nchunk 2\n")
        expect(ftp).to have_received(:close)
      end
    end

    context 'if retrieval fails twice' do
      before do
        allow(ftp).to receive(:retrbinary).and_raise(Net::FTPTempError)
      end

      it 'fails with an error' do
        expect do
          Metar::Raw::Noaa.fetch('the_cccc')
          expect(ftp).to have_received(:close)
        end.to raise_error(RuntimeError, /failed 2 times/)
      end
    end
  end

  context "fetching" do
    let(:noaa_metar) { "#{raw_time}\n#{raw_metar}" }
    let(:raw_time)   { "2010/02/15 10:20" }

    before do
      allow(ftp).to receive(:retrbinary).and_yield(noaa_metar)
      allow(ftp).to receive(:close)
    end

    subject { Metar::Raw::Noaa.new(cccc) }

    it "queries for the station's data" do
      subject.metar

      expect(ftp).to have_received(:retrbinary).with("RETR #{cccc}.TXT", 1024)
      expect(ftp).to have_received(:close)
    end

    it 'sets data to the returned value' do
      subject.metar

      expect(subject.data).to eq(noaa_metar)
    end

    context "times" do
      let(:cccc)      { "OPPS" }
      let(:raw_time)  { "2016/03/31 23:59" }
      let(:raw_metar) do
        "OPPS 312359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011"
      end

      specify "are parsed as UTC/GMT" do
        expect(subject.time.zone).to eq("UTC").or eq("GMT")
      end

      context "across month rollover" do
        let(:after_midnight) { Time.parse("2016/04/01 00:02:11 UTC") }

        specify "have correct date" do
          Timecop.freeze(after_midnight) do
            expect(subject.time.day).to eq(31)
            expect(subject.time.month).to eq(3)
            expect(subject.time.year).to eq(2016)
          end
        end
      end
    end
  end
end
