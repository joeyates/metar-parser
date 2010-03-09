require File.join(File.dirname(__FILE__), 'metar', 'raw')
require File.join(File.dirname(__FILE__), 'metar', 'station')
require File.join(File.dirname(__FILE__), 'metar', 'parser')
require File.join(File.dirname(__FILE__), 'metar', 'report')

module Metar

  module VERSION #:nodoc:
    MAJOR = 0
    MINOR = 1
    TINY = 1
 
    STRING = [MAJOR, MINOR, TINY].join('.')
  end

end
