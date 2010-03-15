require 'rubygems' if RUBY_VERSION < '1.9'
require File.join(File.expand_path(File.dirname(__FILE__) + '/../lib'), 'metar')

Metar::Station.load_local

RAW_EXAMPLE = "2010/02/06 15:20\nLIRQ 061520Z 01007KT 350V050 9999 SCT035 BKN080 08/02 Q1005"
# Use a fixed string for testing
Metar::Raw.instance_eval do
  def fetch(cccc)
    RAW_EXAMPLE
  end
end

# Don't load station data from files
module Metar
  class Station

    class << self

      def all_structures
        [
          { :cccc => 'LIRQ', :country => 'Italy', :latitude => '43-48N', :longitude => '011-12E', :name => 'Firenze / Peretola', :state => '' },
          { :cccc => 'DAAS', :country => 'Algeria', :latitude => '36-11N',  :longitude => '005-25E', :name => 'Setif', :state => '' },
          { :cccc => 'ESSB', :country => 'Sweden', :latitude => '59-21N', :longitude => '017-57E',:name => 'Stockholm / Bromma', :state => '' },
          { :cccc => 'KPDX', :country => 'United States', :latitude => '45-35N', :longitude => '122-36W', :name => 'PORTLAND INTERNATIONAL  AIRPORT', :state => '' },
          { :cccc => 'CYXS', :country => 'Canada', :latitude => '53-53N', :longitude => '122-41W', :name => 'Prince George, B. C.', :state => '' },
        ]
      end
    end
  end
end

require 'test/unit'
