# frozen_string_literal: true

require "i18n"

locales_path = File.expand_path(
  File.join(File.dirname(__FILE__), "..", "..", "locales")
)
I18n.load_path += Dir.glob("#{locales_path}/*.yml")
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
