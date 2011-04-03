require File.join(File.dirname(__FILE__), 'metar', 'raw')
require File.join(File.dirname(__FILE__), 'metar', 'station')
require File.join(File.dirname(__FILE__), 'metar', 'parser')
require File.join(File.dirname(__FILE__), 'metar', 'report')
require File.join(File.dirname(__FILE__), 'metar', 'version')

module Metar

  # Base class for all Metar exceptions
  class MetarError < StandardError
  end

  # Raised when an unrecognized value is found
  class ParseError < MetarError
  end

end
