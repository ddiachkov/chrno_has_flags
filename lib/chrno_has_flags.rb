# encoding: utf-8
require "active_support/dependencies/autoload"

module HasFlags
  extend ActiveSupport::Autoload

  autoload :ARExtension, "has_flags/ar_extension"
  autoload :FlagsProxy,  "has_flags/flags_proxy"
  autoload :VERSION,     "has_flags/version"

  class Railtie < Rails::Railtie
    # Загрузка в AR
    initializer "chrno_has_flags.initialize" do
      ActiveSupport.on_load( :active_record ) do
        puts "--> load has_flags"
        extend HasFlags::ARExtension
      end
    end
  end
end