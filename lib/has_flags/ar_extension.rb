# encoding: utf-8
module HasFlags
  # Макросы для AR.
  module ARExtension
    ##
    # Превращает числовое поле field_name в битовую маску.
    #
    # @param [Array] flags   массив флагов
    # @param [Hash]  options параметры
    #   @option options [String] :field_name ('flags') название поля
    #   @option options [Array]  :default выставленные флаги по умолчанию
    #
    # @example
    #   class User < ActiveRecord::Base
    #     has_flags [ :is_admin, :is_editor ], :field_name => "flags", :default => [ :is_admin ]
    #   end
    #   ...
    #   user.flags.is_admin?         #=> true
    #   user.flags.toggle! :is_admin
    #   user.flags.is_editor = true
    #   user.flags                   #=> [ :is_editor ]
    #   user.available_flags         #=> [ :is_admin, :is_editor ]
    #
    def has_flags( flags, options = {} )
      raise ArgumentError, "flags must be an Array" unless flags.is_a? Array
      raise ArgumentError, "too many flags" if flags.length > 32
      raise ArgumentError, "no flags given" if flags.empty?

      # Настройки по умолчанию
      options[ :field_name ] ||= "flags" # Поле с флагами
      options[ :default    ] ||= [ ]     # Состояние флагов по умолчанию

      # Флаги -- это всегда символы
      flags.map!( &:to_sym )

      make_flags_proxy( flags, options )
      make_flags_scope( flags, options )

      # Сохраняем флаги перед валидацией
      before_validation do |object|
        object.send( options[ :field_name ] ).save_state
      end
    end

    private

    ##
    # Создаёт геттер и сеттер для флагов, используя {HasFlags::FlagsProxy}.
    #
    # @param [Array] flags   флаги
    # @param [Hash]  options параметры (see #has_flags)
    #
    def make_flags_proxy( flags, options )
      field_name = options[ :field_name ]

      # Геттер для прокси объекта
      define_method "#{field_name}_proxy" do
        unless instance_variable_get( "@#{field_name}_proxy" )
          instance_variable_set \
            "@#{field_name}_proxy",
            HasFlags::FlagsProxy.new( self, flags, options )
        else
          instance_variable_get( "@#{field_name}_proxy" )
        end
      end

      # Геттер
      define_method field_name do
        send "#{field_name}_proxy"
      end

      # Сеттер
      define_method "#{field_name}=" do |value|
        send( "#{field_name}_proxy" ).state = value
      end

      # Для вложенных форм (accepts_nested_attributes)
      define_method "#{field_name}_attributes=" do |value|
        send( "#{field_name}_proxy" ).state = value
      end

      # Список доступных флагов
      define_method "available_#{field_name}" do
        flags.dup
      end
    end

    ##
    # Создаёт scope'ы вида has[_not]_<field_name в ед. числе> и <field_name>_eq.
    #
    # @param [Array] flags   флаги
    # @param [Hash]  options параметры (see #has_flags)
    #
    def make_flags_scope( flags, options )
      field_name = options[ :field_name ]

      # ToDo: создать оператор "&" для Arel.

      scope "has_#{field_name.to_s.singularize}", lambda { |flag_to_search|
        flag_mask = FlagsProxy.convert_flags_to_number flags, flag_to_search
        where( "(\"#{table_name}\".\"#{field_name}\" & #{flag_mask}) = #{flag_mask}" )
      }

      scope "has_not_#{field_name.to_s.singularize}", lambda { |flag_to_search|
        flag_mask = FlagsProxy.convert_flags_to_number flags, flag_to_search
        where( "(\"#{table_name}\".\"#{field_name}\" & #{flag_mask}) = 0" )
      }

      scope "#{field_name}_eq".to_sym, lambda { |flags_to_search|
        flags_mask = FlagsProxy.convert_flags_to_number flags, flags_to_search
        where( field_name => flags_mask )
      }
    end
  end
end