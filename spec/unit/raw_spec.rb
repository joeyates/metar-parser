load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

require 'net/ftp'

describe Metar::Raw do
  after :each do
    Metar::Raw.send( :class_variable_set, '@@connection', nil )
  end

  context '.connection' do
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

  end

end

