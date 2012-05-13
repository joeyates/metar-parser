load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
# encoding: utf-8

describe Metar::Station do

  context '.download_local' do

    it 'downloads the station list' do
      file = stub( 'file', :binmode => nil )
      File.stub!( :open => file )

      Metar::Station.                should_receive( :open ).with( /^http/ )

      Metar::Station.download_local
    end

    it 'saves the list to disk' do
      Metar::Station.stub!( :open ).and_return( 'aaa' )
      file = stub( 'file' )

      File.                       should_receive( :open ) do | path, mode, &block |
        path.                     should     =~ %r(data/nsd_cccc.txt$)
        mode.                     should     == 'w'
        block.call file
      end
      file.  should_receive( :write ).with( 'aaa' )

      Metar::Station.download_local
    end

  end

end

