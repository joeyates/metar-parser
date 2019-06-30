# frozen_string_literal: true

module Metar
  module Data
    class Wind < Metar::Data::Base
      def self.parse(raw, strict: false)
        return nil if raw.nil?

        plain_match =
          if strict
            /^(\d{3})(\d{2}(|MPS|KMH|KT))$/
          else
            /^(\d{3})(\d{2,3}(|MPS|KMH|KT))$/
          end

        m1 = raw.match(plain_match)
        if m1
          return nil if m1[1].to_i > 360

          return new(
            raw,
            direction: Metar::Data::Direction.new(m1[1]),
            speed: Metar::Data::Speed.parse(m1[2])
          )
        end

        m2 = raw.match(/^(\d{3})(\d{2})G(\d{2,3}(|MPS|KMH|KT))$/)
        if m2
          return nil if m2[1].to_i > 360

          return new(
            raw,
            direction: Metar::Data::Direction.new(m2[1]),
            speed: Metar::Data::Speed.parse(m2[2] + m2[4]),
            gusts: Metar::Data::Speed.parse(m2[3])
          )
        end

        m3 = raw.match(/^VRB(\d{2})G(\d{2,3})(|MPS|KMH|KT)$/)
        if m3
          speed = m3[1] + m3[3]
          gusts = m3[2] + m3[3]
          return new(
            raw,
            direction: :variable_direction,
            speed: Metar::Data::Speed.parse(speed),
            gusts: Metar::Data::Speed.parse(gusts)
          )
        end

        m4 = raw.match(/^VRB(\d{2}(|MPS|KMH|KT))$/)
        if m4
          speed = Metar::Data::Speed.parse(m4[1])
          return new(raw, direction: :variable_direction, speed: speed)
        end

        m5 = raw.match(%r{^/{3}(\d{2}(|MPS|KMH|KT))$})
        if m5
          speed = Metar::Data::Speed.parse(m5[1])
          return new(raw, direction: :unknown_direction, speed: speed)
        end

        m6 = raw.match(%r{^/////(|MPS|KMH|KT)$})
        if m6
          return new(raw, direction: :unknown_direction, speed: :unknown_speed)
        end

        nil
      end

      attr_reader :direction, :speed, :gusts

      def initialize(raw, direction:, speed:, gusts: nil)
        @raw = raw
        @direction = direction
        @speed = speed
        @gusts = gusts
      end

      def to_s(options = {})
        options = {
          direction_units: :compass,
          speed_units: :kilometers_per_hour
        }.merge(options)
        speed =
          case @speed
          when :unknown_speed
            I18n.t('metar.wind.unknown_speed')
          else
            @speed.to_s(
              abbreviated: true,
              precision: 0,
              units: options[:speed_units]
            )
          end
        direction =
          case @direction
          when :variable_direction
            I18n.t('metar.wind.variable_direction')
          when :unknown_direction
            I18n.t('metar.wind.unknown_direction')
          else
            @direction.to_s(units: options[:direction_units])
          end
        s = "#{speed} #{direction}"

        if !@gusts.nil?
          g = @gusts.to_s(
            abbreviated: true,
            precision: 0,
            units: options[:speed_units]
          )
          s += " #{I18n.t('metar.wind.gusts')} #{g}"
        end

        s
      end
    end
  end
end
