# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

require 'net/ftp'
require 'time'

module MetarRawTestHelper

  def noaa_metar
    raw_time  = "2010/02/15 10:20"
    "#{ raw_time }\n#{ raw_metar }"
  end

  def raw_metar
    "ESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55"
  end

end

describe Metar::Raw::Data do

  include MetarRawTestHelper

  context 'initialization' do

    it 'should parse data, if supplied' do
      @call_time = Time.parse('2012-07-29 16:35')
      Time.stub!(:now).and_return(@call_time)

      raw = Metar::Raw::Data.new(raw_metar)
     
      raw.metar.                  should     == raw_metar 
      raw.cccc.                   should     == 'ESSB'
      raw.time.                   should     == @call_time
    end

  end

end

describe Metar::Raw::Noaa do

  include MetarRawTestHelper

  after :each do
    Metar::Raw::Noaa.send( :class_variable_set, '@@connection', nil )
  end

  context '.connection' do

    context 'uncached' do

      it 'sets up the connection' do
        ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )

        Net::FTP.                   should_receive( :new ).
                                    and_return( ftp )

        Metar::Raw::Noaa.connect
      end

    end

    context 'cached' do

      before :each do
        @ftp = stub( 'ftp' )
        Metar::Raw::Noaa.send( :class_variable_set, '@@connection', @ftp )
      end

      it 'does not connect to FTP' do
        Net::FTP.                   should_not_receive( :new )

        Metar::Raw::Noaa.connection
      end

      it 'returns the cached connection' do
        connection = Metar::Raw::Noaa.connection

        connection.               should     == @ftp
      end

    end
    
  end

  context '.connect' do

    it 'sets up the connection' do
      ftp = stub( 'ftp' )

      Net::FTP.                   should_receive( :new ).
                                  and_return( ftp )
      ftp.                        should_receive( :login )
      ftp.                        should_receive( :chdir )
      ftp.                        should_receive( :passive= ).
                                  with( true )

      Metar::Raw::Noaa.connect
    end

  end

  context '.fetch' do

    it 'uses the connection' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil, :retrbinary => nil )

      Net::FTP.                   should_receive( :new ).
                                  and_return( ftp )

      Metar::Raw::Noaa.fetch( 'the_cccc' )
    end

    it 'downloads the raw report' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      Net::FTP.stub!( :new ).and_return( ftp )

      ftp.                        should_receive( :retrbinary ) do | *args, &block |
        args[ 0 ].                should     == 'RETR the_cccc.TXT'
        args[ 1 ].                should     be_a Fixnum
      end

      Metar::Raw::Noaa.fetch( 'the_cccc' )
    end

    it 'returns the data' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      def ftp.retrbinary( *args, &block )
        block.call "chunk 1\n"
        block.call "chunk 2\n"
      end
      Net::FTP.stub!( :new ).and_return( ftp )
 
      raw = Metar::Raw::Noaa.fetch( 'the_cccc' )

      raw.                        should     == "chunk 1\nchunk 2\n"
    end

    it 'retries retrieval once' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      def ftp.attempt
        @attempt
      end
      def ftp.attempt=(a)
        @attempt = a
      end
      ftp.attempt = 0
      def ftp.retrbinary( *args, &block )
        self.attempt = self.attempt + 1
        raise Net::FTPTempError if self.attempt == 1
        block.call "chunk 1\n"
        block.call "chunk 2\n"
      end
      Net::FTP.stub!( :new ).and_return( ftp )
 
      raw = Metar::Raw::Noaa.fetch( 'the_cccc' )

      raw.                        should     == "chunk 1\nchunk 2\n"
    end

    it 'fails with an error, if retrieval fails twice' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      def ftp.attempt
        @attempt
      end
      def ftp.attempt=(a)
        @attempt = a
      end
      ftp.attempt = 0
      def ftp.retrbinary( *args, &block )
        self.attempt = self.attempt + 1
        raise Net::FTPTempError
      end
      Net::FTP.stub!( :new ).and_return( ftp )

      expect do
        Metar::Raw::Noaa.fetch( 'the_cccc' )
      end.                        to         raise_error( RuntimeError, /failed 2 times/)
    end

  end

  context 'initialization' do
  
    it 'should accept CCCC codes' do
      raw = Metar::Raw::Noaa.new( 'XXXX' )

      raw.cccc.                   should     == 'XXXX'
    end
      
    it 'should accept Stations' do
      station = stub( 'Metar::Station', :cccc => 'YYYY' )
      raw = Metar::Raw::Noaa.new( station )

      raw.cccc.                   should     == 'YYYY'
    end
    
  end

  context 'lazy loading' do
    
    it 'should fetch data on demand' do
      raw = Metar::Raw::Noaa.new( 'ESSB' )

      Metar::Raw::Noaa.           should_receive(:fetch).
                                  with( 'ESSB' ).
                                  and_return(noaa_metar)

      raw.metar

      raw.data.                   should     == noaa_metar 
    end

  end

end

