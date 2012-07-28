load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

require 'net/ftp'

describe Metar::Raw do

  after :each do
    Metar::Raw.send( :class_variable_set, '@@connection', nil )
  end

  context '.connection' do

    context 'uncached' do

      it 'sets up the connection' do
        ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )

        Net::FTP.                   should_receive( :new ).
                                    and_return( ftp )

        Metar::Raw.connect
      end

    end

    context 'cached' do

      before :each do
        @ftp = stub( 'ftp' )
        Metar::Raw.send( :class_variable_set, '@@connection', @ftp )
      end

      it 'does not connect to FTP' do
        Net::FTP.                   should_not_receive( :new )

        Metar::Raw.connection
      end

      it 'returns the cached connection' do
        connection = Metar::Raw.connection

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

      Metar::Raw.connect
    end

  end

  context '.fetch' do

    it 'uses the connection' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil, :retrbinary => nil )

      Net::FTP.                   should_receive( :new ).
                                  and_return( ftp )

      Metar::Raw.fetch( 'the_cccc' )
    end

    it 'downloads the raw report' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      Net::FTP.stub!( :new ).and_return( ftp )

      ftp.                        should_receive( :retrbinary ) do | *args, &block |
        args[ 0 ].                should     == 'RETR the_cccc.TXT'
        args[ 1 ].                should     be_a Fixnum
      end

      Metar::Raw.fetch( 'the_cccc' )
    end

    it 'returns the data' do
      ftp = stub( 'ftp', :login => nil, :chdir => nil, :passive= => nil )
      def ftp.retrbinary( *args, &block )
        block.call "chunk 1\n"
        block.call "chunk 2\n"
      end
      Net::FTP.stub!( :new ).and_return( ftp )
 
      raw = Metar::Raw.fetch( 'the_cccc' )

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
 
      raw = Metar::Raw.fetch( 'the_cccc' )

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
        Metar::Raw.fetch( 'the_cccc' )
      end.                        to         raise_error( RuntimeError, /failed 2 times/)
    end

  end

  context 'initialization' do
  
    it 'should accept CCCC codes' do
      raw = Metar::Raw.new( 'XXXX' )

      raw.cccc.                   should     == 'XXXX'
    end
      
    it 'should accept Stations' do
      station = stub( 'Metar::Station', :cccc => 'YYYY' )
      raw = Metar::Raw.new( station )

      raw.cccc.                   should     == 'YYYY'
    end

    it 'should parse data, if supplied' do
      raw = Metar::Raw.new( nil, raw_metar )
     
      raw.data.                   should     == raw_metar 
      raw.raw_time.               should     == @raw_time
      raw.metar.                  should     == @metar 
      raw.cccc.                   should     == 'ESSB'
      raw.time.                   should     == Time.parse( @raw_time ) 
    end

    it 'should fail if neither the station, nor the data are supplied' do
      expect do
        Metar::Raw.new
      end.                        to         raise_error( RuntimeError, /Supply either a Station or a METAR string/ )
    end
    
  end

  context 'lazy loading' do
    
    it 'should fetch data on demand' do
      raw = Metar::Raw.new( 'ESSB' )

      Metar::Raw.                 should_receive( :fetch ).
                                  with( 'ESSB' ).
                                  and_return( raw_metar )

      raw.metar

      raw.data.                   should     == raw_metar 
    end

  end

  def raw_metar
    @raw_time  = "2010/02/15 10:20"
    @metar     = "ESSB 151020Z 26003KT 2000 R12/1000N R30/1500N VV002 M07/M07 Q1013 1271//55"
    "#{ @raw_time }\n#{ @metar }"
  end

end

