metar - Downloads and parses weather status
===========================================

The information comes from the National Oceanic and Atmospheric Association's raw data source.

Implementation
==============

* Parses METAR strings using a state machine.

Usage
=====

```ruby
require 'rubygems' if RUBY_VERSION < '1.9'
require 'metar'
```

Examples
========

Hello World
-----------

This prints the latest weather report for Portland International Airport:

```ruby
station = Metar::Station.find_by_cccc( 'KPDX' )
puts station.report.to_s
```

Countries
---------

List countries:

```ruby
puts Metar::Station.countries
```

Find a country's weather stations:

```ruby
spanish = Metar::Station.find_all_by_country( 'Spain' )
```

Get The Data
------------
```ruby
station = Metar::Station.find_by_cccc( 'KPDX' )
parser  = station.parser
puts parser.temperature.value
```


The METAR Data Format
=====================

* WMO
  * http://www.wmo.int/pages/prog/www/WMOCodes/Manual/Volume-I-selection/Sel2.pdf (pages 27-38)
  * http://dcaa.slv.dk:8000/icaodocs/Annex%203%20-%20Meteorological%20Service%20for%20International%20Air%20Navigation/Cover%20sheet%20to%20AMDT%2074.pdf (Table A3-2. Template for METAR and SPECI)
  * http://booty.org.uk/booty.weather/metinfo/codes/METAR_decode.htm

* United states:
  * http://www.nws.noaa.gov/oso/oso1/oso12/fmh1/fmh1ch12.htm
  * http://www.ofcm.gov/fmh-1/pdf/FMH1.pdf
  * http://weather.cod.edu/notes/metar.html
  * http://www.met.tamu.edu/class/METAR/metar-pg3.html - incomplete

Alternative Software
====================

Ruby
----

Other Ruby libraries offering METAR parsing:
* ruby-metar - http://github.com/brandonh/ruby-metar
* ruby-wx - http://hans.fugal.net/src/ruby-wx/doc/
There are many reports (WMO) that these libraries do not parse.

There are two gems which read the National Oceanic and Atmospheric Association's XML weather data feeds:
* noaa-weather - Ruby interface to NOAA SOAP interface
* noaa - http://github.com/outoftime/noaa

Interactive map:
* http://www.spatiality.at/metarr/frontend/

