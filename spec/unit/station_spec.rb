load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

require 'stringio'

describe Metar::Station do

  before :each do
    @file = stub( 'file' )
  end

  context '.download_local' do

    it 'downloads the station list' do
      File.stub!( :open => @file )

      Metar::Station.             should_receive( :open ).
                                  with( /^http/ )

      Metar::Station.download_local
    end

    it 'saves the list to disk' do
      Metar::Station.stub!( :open ).and_return( 'aaa' )

      File.                       should_receive( :open ) do | path, mode, &block |
        path.                     should     =~ %r(data/nsd_cccc.txt$)
        mode.                     should     == 'w'
        block.call @file
      end
      @file.                      should_receive( :write ).
                                  with( 'aaa' )

      Metar::Station.download_local
    end

  end

  context '.load_local' do

    it 'downloads the station list, if missing, then loads it' do
      File.                       should_receive( :exist? ).
                                  and_return( false )
      Metar::Station.             should_receive( :open ).
                                  and_return( 'aaa' )
      File.                       should_receive( :open ).once.with( %r(nsd_cccc.txt), 'w' )
      File.                       should_receive( :open ).once.with( %r(nsd_cccc.txt) )

      Metar::Station.load_local
    end

    it 'loads the file, if already present' do
      File.                       should_receive( :exist? ).
                                  and_return( true )

      File.                       should_receive( :open ).once.with( %r(nsd_cccc.txt) )

      Metar::Station.load_local
    end

  end

  context '.countries' do

    def nsd_file
#0    1  2   3    4     5       6 7        8         9        10        11  12  13
#CCCC;??;???;name;state;country;?;latitude;longitude;latitude;longitude;???;???;?
      nsd_text =<<EOT
AAAA;00;000;Airport A1;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P
AAAB;00;000;Airport A2;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P
BBBA;00;000;Airport B1;;Bbbbb;1;11-03S;055-24E;11-03S;055-24E;000;000;P
EOT
      StringIO.new( nsd_text )
    end

    def preload_data
      File.stub!( :exist? ).and_return( true )
      File.stub!( :open ).with( %r(nsd_cccc.txt) ).and_return( nsd_file )
      Metar::Station.load_local
    end

    before :each do
      preload_data
    end

    it 'lists unique countries' do
      Metar::Station.countries.   should     == [ 'Aaaaa', 'Bbbbb' ]
    end

  end

end

