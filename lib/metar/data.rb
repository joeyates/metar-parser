# frozen_string_literal: true

module Metar
  module Data
    autoload :Base, "metar/data/base"
    autoload :DensityAltitude, "metar/data/density_altitude"
    autoload :Direction, "metar/data/direction"
    autoload :Distance, "metar/data/distance"
    autoload :Lightning, "metar/data/lightning"
    autoload :Observer, "metar/data/observer"
    autoload :Pressure, "metar/data/pressure"
    autoload :Remark, "metar/data/remark"
    autoload :RunwayVisibleRange, "metar/data/runway_visible_range"
    autoload :SkyCondition, "metar/data/sky_condition"
    autoload :Speed, "metar/data/speed"
    autoload :StationCode, "metar/data/station_code"
    autoload :Temperature, "metar/data/temperature"
    autoload :TemperatureAndDewPoint, "metar/data/temperature_and_dew_point"
    autoload :Time, "metar/data/time"
    autoload :VariableWind, "metar/data/variable_wind"
    autoload :VerticalVisibility, "metar/data/vertical_visibility"
    autoload :Visibility, "metar/data/visibility"
    autoload :VisibilityRemark, "metar/data/visibility_remark"
    autoload :WeatherPhenomenon, "metar/data/weather_phenomenon"
    autoload :Wind, "metar/data/wind"
  end
end
