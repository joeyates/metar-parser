load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

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

end

