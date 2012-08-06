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

  end

end

