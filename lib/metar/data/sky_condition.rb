class Metar::Data::SkyCondition < Metar::Data::Base
  QUANTITY = {'BKN' => 'broken', 'FEW' => 'few', 'OVC' => 'overcast', 'SCT' => 'scattered'}
  CONDITION = {
    'CB'  => 'cumulonimbus',
    'TCU' => 'towering cumulus',
    '///' => nil, # cloud type unknown as observed by automatic system (15.9.1.7)
    ''    => nil,
  }
  CLEAR_SKIES = [
    'NSC', # WMO
    'NCD', # WMO
    'CLR',
    'SKC',
  ]

  def self.parse(raw)
    case
    when CLEAR_SKIES.include?(raw)
      new(raw)
    when raw =~ /^(BKN|FEW|OVC|SCT)(\d+|\/{3})(CB|TCU|\/{3}|)?$/
      quantity = QUANTITY[$1]
      height   =
        if $2 == '///'
          nil
        else
          Metar::Data::Distance.new($2.to_i * 30.48)
        end
      type = CONDITION[$3]
      new(raw, quantity: quantity, height: height, type: type)
    when raw =~ /^(CB|TCU)$/
      type = CONDITION[$1]
      new(raw, type: type)
    else
      nil
    end
  end

  attr_reader :quantity, :height, :type

  def initialize(raw, quantity: nil, height: nil, type: nil)
    @raw = raw
    @quantity, @height, @type = quantity, height, type
  end

  def to_s
    if @height.nil?
      to_summary
    else
      to_summary + ' ' + I18n.t('metar.altitude.at') + ' ' + height.to_s
    end
  end

  def to_summary
    if @quantity == nil and @height == nil and @type == nil
      I18n.t('metar.sky_conditions.clear skies')
    else
      type = @type ? ' ' + @type : ''
      I18n.t("metar.sky_conditions.#{@quantity}#{type}")
    end
  end
end
