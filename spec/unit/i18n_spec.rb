require 'spec_helper'

describe I18n do
  it 'adds our locales to the load path' do
    project_root = File.expand_path('../..', File.dirname(__FILE__))
    english_path = File.join(project_root, 'locales', 'en.yml')
    italian_path = File.join(project_root, 'locales', 'it.yml')
    german_path  = File.join(project_root, 'locales', 'de.yml')

    expect(I18n.load_path).to include(english_path)
    expect(I18n.load_path).to include(italian_path)
    expect(I18n.load_path).to include(german_path)
  end

  it 'falls back do the language translation when a region-specific translation is not available' do
    old_locale = I18n.locale
    I18n.locale = :'en-FOO'
    expect(I18n.t('metar.altitude.at')).to eq('at')
    I18n.locale = old_locale
  end
end

