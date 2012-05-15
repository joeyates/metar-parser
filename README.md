metar-parser [![Build Status](https://secure.travis-ci.org/joeyates/metar-parser.png)][Continuous Integration]
============

*Get latest weather reports from weather stations worldwide*

  * [Continuous Integration]

[Continuous Integration]: http://travis-ci.org/joeyates/metar-parser "Build status by Travis-CI"

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

