require 'rubygems' if RUBY_VERSION < '1.9'
require 'dhaka'

module Metar

  class Evaluator < Dhaka::Evaluator

    self.grammar = Metar::Grammar

    attr_reader :raw, :parser, :report

    def initialize(raw)
      @raw = raw.to_s
      @standard = nil # We get the standard before we instantiate the report
    end

    def run!
      tokens = Metar::Lexer.lex(@raw)
      @parser = Metar::Parser.parse(tokens)
      evaluate(@parser)
    end

    define_evaluation_rules(:raise_error => true) do

      # Define no-op rules
      %w|
          no_wind
          temperature_remark numeric_remark
          no_united_states_pressure
          no_temperature_dew_point
          no_pressure symbol_remark no_condition no_visibility
          no_remark no_remarks missing_visibility
          missing_weather no_weather missing_sky
        |.each do |production_name|
        eval("for_#{production_name} do end")
      end

      for_remarks do
      end
      for_scattered_cloud do
      end
      for_broken_cloud do
      end
      for_few do
      end
      for_sea_level_pressure do
      end
      for_wind_variable do
      end
      for_no_recent do
      end

      for_international do
        @standard = :international
        child_nodes.each do |node|
          evaluate(node)
        end
      end

      for_united_states do
        @standard = :united_states
        child_nodes.each do |node|
          evaluate(node)
        end
      end

      for_location do        
        @report = Metar::Report.new(child_nodes[0].token.value)
        @report.standard = @standard # We saved this earlier
      end

      for_date do
        child_nodes[0].token.value =~ /(\d\d)(\d\d)(\d\d)Z/
        today = Date.today
        day = $1.to_i
        hour = $2.to_i
        minute = $3.to_i
        days_month = (day <= today.day)? today.clone : today << 1
        @report.time = Time.gm(days_month.year, days_month.month, day, hour, minute)
      end

      for_no_cor_auto do
        @report.observer = :present
      end

      for_auto do
        @report.observer = :automatic
      end

      for_wind do
        @report.wind = child_nodes[0].token.value
      end

      for_american_visibility do
        @report.visibility = child_nodes[0].token.value
      end

      for_numeric_visibility do
        @report.visibility = child_nodes[0].token.value
      end

      for_kilometers_visibility do
        @report.visibility = child_nodes[0].token.value
      end

      for_present_weather_item do
        @report.present_weather ||= []
        @report.present_weather << child_nodes[0].token.value
      end

      for_condition do
        @report.sky = child_nodes[0].tokens.collect { |token| token.value }
      end

      for_temperature_dew_point do
        temperature_dew_point = child_nodes[0].token.value
        temperature, dew_point = temperature_dew_point.split('/')
        @report.temperature = temperature
        @report.dew_point = dew_point
      end

      for_altimeter_hectopascals do
        @report.sea_level_pressure = child_nodes[0].token.value
      end

      for_altimeter_inches_hg do
        @report.sea_level_pressure = child_nodes[0].token.value
      end

    end

  end

end
