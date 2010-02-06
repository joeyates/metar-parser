require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'

module Metar
  
  class Grammar < Dhaka::Grammar

    for_symbol(Dhaka::START_SYMBOL_NAME) do
      united_states             %w| Location DateTime CorAuto Wind UnitedStatesVisibility  PresentWeather SkyConditions TemperatureDewPoint UnitedStatesSeaLevelPressure                RemarksList |
      international             %w| Location DateTime CorAuto Wind InternationalVisibility PresentWeather SkyConditions TemperatureDewPoint InternationalSeaLevelPressure RecentWeather RemarksList |
    end

    for_symbol('Location') do
      location                  %w| symbol |
    end

    for_symbol('DateTime') do
      date                      %w| datetime_literal |
    end

    for_symbol('CorAuto') do
      cor                       %w| cor_literal |
      auto                      %w| auto_literal |
      no_cor_auto               %w||
    end

    for_symbol('Wind') do
      wind                      %w| windgroup_literal |
      wind_variable             %w| windgroup_literal variable_windgroup_literal |
      no_wind                   %w||
    end

    for_symbol('UnitedStatesVisibility') do
      american_visibility       %w| standard_miles_literal |
    end
  
    for_symbol('InternationalVisibility') do
      numeric_visibility        %w| numeric |
      kilometers_visibility     %w| kilometers_literal |
      missing_visibility        %w| four_slashes_literal | # Is '////' legal? I added this as I found it, e.g. AYMO 041500Z AUTO 35010KT //// // ////// 28/22 Q1009
      no_visibility             %w||
    end

    for_symbol('PresentWeather') do
      present_weather           %w| PresentWeatherItem |
      missing_weather           %w| two_slashes_literal | # Is '//' legal? I added this as I found it, e.g. AYMO 041500Z AUTO 35010KT //// // ////// 28/22 Q1009
      no_weather                %w||
    end

    for_symbol('PresentWeatherItem') do
      present_weather_item      %w| present_weather_literal PresentWeather |
    end

    for_symbol('SkyConditions') do
      condition                 %w| SkyCondition |
      missing_sky               %w| six_slashes_literal | # Is '//////' legal? I added this as I found it, e.g. AYMO 041500Z AUTO 35010KT //// // ////// 28/22 Q1009
      no_condition              %w||
    end

    for_symbol('SkyCondition') do
      few                       %w| few_literal SkyConditions |
      scattered_cloud           %w| scattered_cloud_literal SkyConditions |
      broken_cloud              %w| broken_cloud_literal SkyConditions |
    end

    for_symbol('TemperatureDewPoint') do
      temperature_dew_point     %w| temperature_dew_point_literal |
      no_temperature_dew_point  %w||
    end

    for_symbol('UnitedStatesSeaLevelPressure') do
      altimeter_inches_hg       %w| altimeter_inches_hg_literal |
      no_united_states_pressure %w||
    end

    for_symbol('InternationalSeaLevelPressure') do
      altimeter_hectopascals    %w| altimeter_hectopascals_literal |
      no_pressure               %w||
    end

    for_symbol('RecentWeather') do
      nosig                     %w| nosig_literal |
      no_recent                 %w||
    end

    for_symbol('RemarksList') do
      remarks                   %w| remark_literal Remarks |
      no_remarks                %w||
    end

    for_symbol('Remarks') do
      sea_level_pressure        %w| sea_level_pressure_literal Remarks |
      numeric_remark            %w| numeric Remarks |
      temperature_remark        %w| temperature_dew_point_literal Remarks |
      symbol_remark             %w| symbol Remarks |
      no_remark                 %w||
    end

  end

end
