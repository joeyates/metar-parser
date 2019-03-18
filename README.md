metar-parser [![Build Status](https://secure.travis-ci.org/joeyates/metar-parser.png)][Continuous Integration]
============

*Get latest weather reports from weather stations worldwide*

  * [Source Code]
  * [API documentation]
  * [Rubygem]
  * [Continuous Integration]

[Source Code]: https://github.com/joeyates/metar-parser "Source code at GitHub"
[API documentation]: http://rubydoc.info/gems/metar-parser/frames "RDoc API Documentation at Rubydoc.info"
[Rubygem]: http://rubygems.org/gems/metar-parser "Ruby gem at rubygems.org"
[Continuous Integration]: http://travis-ci.org/joeyates/metar-parser "Build status by Travis-CI"

The information comes from the National Oceanic and Atmospheric Association's raw data source.

# Installation

```ruby
require 'metar'
```

# Examples

## Hello World

This prints the latest weather report for Portland International Airport:

```ruby
station = Metar::Station.find_by_cccc('KPDX')
puts station.report.to_s
```

## Using Your Own Raw Data

The parser needs to know the full date when the reading was taken. Unfortunately,
the METAR string itself only contains the day of the month.

### When you know the date of the reading

Use `Metar::Raw::Data` and supply the date as the second parameter:

```ruby
metar_string = "KHWD 280554Z AUTO 29007KT 10SM OVC008 14/12 A3002 RMK AO2 SLP176 T01390117 10211\n"
raw    = Metar::Raw::Data.new(metar_string, reading_date)
parser = Metar::Parser.new(raw)
```

### When you do not know the date

Use `Metar::Raw::Metar` - the library will choose the date as the most recent
day with the day of the month indicated in the METAR string:

I.e. on 11th April 2016:

```ruby
metar_string = "KHWD 280554Z AUTO 29007KT 10SM OVC008 14/12 A3002 RMK AO2 SLP176 T01390117 10211\n"
raw    = Metar::Raw::Metar.new(metar_string)
raw.time.to_s                              # => "2016-03-28"
parser = Metar::Parser.new(raw)
```

## Access Specific Data

```ruby
station = Metar::Station.find_by_cccc('KPDX')
parser  = station.parser
puts parser.temperature.value
```

# Countries

List countries:

```ruby
puts Metar::Station.countries
```

Find a country's weather stations:

```ruby
spanish = Metar::Station.find_all_by_country('Spain')
```

# Translations

Translations are available for the following languages (and region):
* :de
* :en
* :'en-US'
* :it
* :'pt-BR'

Thanks to the I18n gem's fallback mechanism, under regional locales, language generic
translations will be used if a region-specific translation is not available.
I.e.
```
I18n.locale = :'en-US'
I18n.t('metar.station_code.title') # station code
```

# The METAR Format

See `doc/metar_format`.

# Compliance

By default, the parser runs in 'loose' compliance mode. That means that it tries to
accept non-standard input.

If you only want to accept standards-compliant METAR strings, do this:

```ruby
Metar::Parse.compliance = :strict
```

Changelog
=========

1.0.0
-----
This version introduces a major change to the Metar::Raw class.

Previously, this class downloaded METAR data from the NOAA FTP site.
The old functionality has been moved to Metar::Raw::Noaa. The new class,
Metar::Raw::Data accepts a METAR string as a parameter - allowing the user to
parse METAR strings without necessarily contacting the NOAA.

Contributors
============

* [Joe Yates](https://github.com/joeyates)
* [Derek Johnson](https://github.com/EpicDraws)
* [Florian Egermann and Mathias Wollin](https://github.com/math)

Alternative Software
====================

Ruby
----

Other Ruby libraries offering METAR parsing:

* [ruby-metar]
* [ruby-wx]

There are many reports (WMO) that these libraries do not parse.

[ruby-metar]: http://github.com/brandonh/ruby-metar
[ruby-wx]: http://hans.fugal.net/src/ruby-wx/doc/

There are two gems which read the National Oceanic and Atmospheric Association's XML weather data feeds:

* [noaa]
* [noaa-weather]

[noaa]: http://github.com/outoftime/noaa
[noaa-weather]: http://rubygems.org/gems/noaa-weather "Ruby interface to NOAA SOAP interface"

Other
-----

* [Interactive map]

[Interactive map]: http://www.spatiality.at/metarr/frontend/

