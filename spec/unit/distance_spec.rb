load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

describe Metar::Distance do

  context '#value' do

    it 'should treat the parameter as meters' do
      @distance = Metar::Distance.new( 12345.67 )

      @distance.units.            should     == :meters
      @distance.value.            should     == 12345.67
    end

  end

  context '#to_s' do

    it 'should default to meters' do
      @distance = Metar::Distance.new( rand * 1000.0 )

      @distance.to_s.             should     =~ %r(^\d+m)
    end

    it 'should round down to the nearest meter' do
      @distance = Metar::Distance.new( 12.345 )

      @distance.to_s.             should     == '12m'
    end

    it 'should round up to meters' do
      @distance = Metar::Distance.new( 8.750 )

      @distance.to_s.             should     == '9m'
    end

    it 'should allow units overrides' do
      @distance = Metar::Distance.new( 12345.67 )

      @distance.to_s( :units => :kilometers ).
                                  should     == '12km'
    end

    it 'should allow precision overrides' do
      @distance = Metar::Distance.new( 12.34567 )

      @distance.to_s( :precision => 1 ).
                                  should     == '12.3m'
    end

    it 'should handle nil' do
      @distance = Metar::Distance.new( nil )

      @distance.to_s.             should     == 'unknown'
    end

    context 'translated' do

      before :each do
        @locale     = I18n.locale
        I18n.locale = :it
      end

      after :each do
        I18n.locale = @locale
      end

      it 'should allow precision overrides' do
        @distance = Metar::Distance.new( 12.34567 )

        @distance.to_s( :precision => 1 ).
                                    should     == '12,3m'
      end

      it 'should handle nil' do
        @distance = Metar::Distance.new( nil )

        @distance.to_s.           should     == 'sconosciuto'
      end

    end

  end

end

