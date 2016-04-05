# encoding: utf-8
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
    let(:call_time) { Time.parse('2012-07-29 16:35') }

    before do
      now = call_time
      allow(Time).to receive(:now) { now }
    end

    it 'parses data' do
      raw = Metar::Raw::Data.new(raw_metar)
     
      expect(raw.metar).to eq(raw_metar)
      expect(raw.cccc).to eq('ESSB')
      expect(raw.time).to eq(call_time)
    end
  end
end

describe Metar::Raw::Noaa do
  include MetarRawTestHelper

  let(:cccc) { "ESSB" }
  let(:ftp) { double('ftp', :login => nil, :chdir => nil, :passive= => nil, :retrbinary => nil) }

  before do
    allow(Net::FTP).to receive(:new) { ftp }
  end

  after :each do
    Metar::Raw::Noaa.send(:class_variable_set, '@@connection', nil)
  end

  context '.connection' do
    context 'uncached' do
      it 'sets up the connection' do
        Metar::Raw::Noaa.connect

        expect(Net::FTP).to have_received(:new)
      end
    end

    context 'cached' do
      before :each do
        Metar::Raw::Noaa.send(:class_variable_set, '@@connection', ftp)
      end

      it 'does not connect to FTP' do
        Metar::Raw::Noaa.connection

        expect(Net::FTP).to_not have_received(:new)
      end

      it 'returns the cached connection' do
        connection = Metar::Raw::Noaa.connection

        expect(connection).to eq(ftp)
      end
    end
  end

  context '.connect' do
    it 'sets up the connection' do
      Metar::Raw::Noaa.connect

      expect(Net::FTP).to have_received(:new)
      expect(ftp).to have_received(:login).with(no_args)
      expect(ftp).to have_received(:chdir).with('data/observations/metar/stations')
      expect(ftp).to have_received(:passive=).with(true)
    end
  end

  context '.fetch' do
    it 'uses the connection' do
      Metar::Raw::Noaa.fetch('the_cccc')

      expect(Net::FTP).to have_received(:new)
    end

    it 'downloads the raw report' do
      Metar::Raw::Noaa.fetch('the_cccc')

      expect(ftp).to have_received(:retrbinary).with('RETR the_cccc.TXT', kind_of(Fixnum))
    end

    it 'returns the data' do
      def ftp.retrbinary(*args, &block)
        block.call "chunk 1\n"
        block.call "chunk 2\n"
      end
      raw = Metar::Raw::Noaa.fetch('the_cccc')

      expect(raw).to eq("chunk 1\nchunk 2\n")
    end

    it 'retries retrieval once' do
      def ftp.attempt
        @attempt
      end
      def ftp.attempt=(a)
        @attempt = a
      end
      ftp.attempt = 0
      def ftp.retrbinary(*args, &block)
        self.attempt = self.attempt + 1
        raise Net::FTPTempError if self.attempt == 1
        block.call "chunk 1\n"
        block.call "chunk 2\n"
      end
 
      raw = Metar::Raw::Noaa.fetch('the_cccc')

      expect(raw).to eq("chunk 1\nchunk 2\n")
    end

    it 'fails with an error, if retrieval fails twice' do
      def ftp.attempt
        @attempt
      end
      def ftp.attempt=(a)
        @attempt = a
      end
      ftp.attempt = 0
      def ftp.retrbinary(*args, &block)
        self.attempt = self.attempt + 1
        raise Net::FTPTempError
      end

      expect do
        Metar::Raw::Noaa.fetch('the_cccc')
      end.to raise_error(RuntimeError, /failed 2 times/)
    end
  end

  context 'initialization' do
    it 'should accept CCCC codes' do
      raw = Metar::Raw::Noaa.new('XXXX')

      expect(raw.cccc).to eq('XXXX')
    end
      
    it 'should accept Stations' do
      station = double('Metar::Station', :cccc => 'YYYY')
      raw = Metar::Raw::Noaa.new(station)

      expect(raw.cccc).to eq('YYYY')
    end
  end

  context "fetching" do
    let(:noaa_metar) { "#{raw_time}\n#{raw_metar}" }
    let(:raw_time)   { "2010/02/15 10:20" }

    before do
      allow(Metar::Raw::Noaa).to receive(:fetch) { noaa_metar }
    end

    subject { Metar::Raw::Noaa.new(cccc) }

    it 'sets data to the returned value' do
      subject.metar

      expect(subject.data).to eq(noaa_metar)
    end

    context "times" do
      let(:cccc)      { "OPPS" }
      let(:raw_time)  { "2016/03/31 23:59" }
      let(:raw_metar) { "OPPS 312359Z 23006KT 4000 HZ SCT040 SCT100 17/12 Q1011" }

      specify "are parsed as UTC" do
        expect(subject.time.zone).to eq("UTC")
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
