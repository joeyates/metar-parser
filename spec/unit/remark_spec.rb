# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )
 
describe Metar::Remark do

  context '.parse' do

    it 'should delegate to subclasses' do
      Metar::Remark.parse('21012').  should    be_a(Metar::TemperatureExtreme)
    end

    it 'should return nil for unrecognised' do
      Metar::Remark.parse('FOO').    should    be_nil
    end

    context '6-hour maximum or minimum' do

      [
        ['positive maximum', '10046', [:maximum,  4.6]],
        ['negative maximum', '11012', [:maximum, -1.2]],
        ['positive minimum', '20046', [:minimum,  4.6]],
        ['negative minimum', '21012', [:minimum, -1.2]],
      ].each do |docstring, raw, expected|
        example docstring do
          Metar::Remark.parse(raw).
                                should    be_temperature_extreme(*expected)
        end
      end

    end

    context '24-hour maximum and minimum' do

      it 'returns minimum and maximum' do
        max, min = Metar::Remark.parse('400461006')

        max.                      should    be_temperature_extreme(:maximum,  4.6)
        min.                      should    be_temperature_extreme(:minimum, -0.6)
      end

    end

    context 'pressure tendency' do

      it 'steady_then_decreasing' do
        pt = Metar::Remark.parse('58033')

        pt.                       should    be_a(Metar::PressureTendency)
        pt.character.             should    == :steady_then_decreasing
        pt.value.                 should    == 3.3
      end

    end

    context '3-hour and 6-hour precipitation' do

      it '60009' do
        pr = Metar::Remark.parse('60009')
        
        pr.                       should    be_a(Metar::PrecipitationRecent)
        pr.amount.value.          should    == 0.002286
      end

    end

    context '24-hour precipitation' do

      it '70015' do
        pr = Metar::Remark.parse('70015')
        
        pr.                       should    be_a(Metar::Precipitation24Hour)
        pr.amount.value.          should    == 0.003810
      end

    end

  end

end

