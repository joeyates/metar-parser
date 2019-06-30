# frozen_string_literal: true

module Metar
  module Data
    class Time < Metar::Data::Base
      def self.parse(raw, year: nil, month: nil, strict: true)
        year ||= DateTime.now.year
        month ||= DateTime.now.month

        date_matcher =
          if strict
            /^(\d{2})(\d{2})(\d{2})Z$/
          else
            /^(\d{1,2})(\d{2})(\d{2})Z$/
          end

        m1 = raw.match(date_matcher)
        if m1
          day = m1[1].to_i
          hour = m1[2].to_i
          minute = m1[3].to_i
        else
          return nil if strict

          m2 = raw.match(/^(\d{1,2})(\d{2})Z$/)
          return nil if !m2

          # The day is missing, use today's date
          day = ::Time.now.day
          hour = m2[1].to_i
          minute = m2[2].to_i
        end

        new(
          raw,
          strict: strict,
          year: year, month: month, day: day, hour: hour, minute: minute
        )
      end

      attr_reader :strict
      attr_reader :year
      attr_reader :month
      attr_reader :day
      attr_reader :hour
      attr_reader :minute

      def initialize(raw, strict:, year:, month:, day:, hour:, minute:)
        @raw = raw
        @strict = strict
        @year = year
        @month = month
        @day = day
        @hour = hour
        @minute = minute
      end

      def value
        ::Time.gm(year, month, day, hour, minute)
      end
    end
  end
end
