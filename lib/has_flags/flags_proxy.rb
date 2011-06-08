# encoding: utf-8
module HasFlags

  ##
  # Класс обёртка над полем битовой маски.
  #
  class FlagsProxy
    # @param [ActiveRecord::Base] object объект с флагами
    # @param [Array] flags массив со всеми возможными флагами
    # @param [Hash] options параметры (see HasFlags::ARExtension#has_flags)
    def initialize( object, flags, options )
      @object  = object
      @flags   = flags
      @options = options

      # Для каждого флага создаём геттер и сеттер.
      @flags.each do |flag|
        instance_eval %{
          def #{flag}
            @state.include? #{flag.inspect}
          end

          alias #{flag}? #{flag}

          def #{flag}=( value )
            if value
              @state << #{flag.inspect} unless #{flag}
            else
              @state.delete #{flag.inspect} if #{flag}
            end
          end
        }
      end

      load_state
    end

    ##
    # Инвертирует флаг.
    # @param [Symbol] flag название флага
    #
    def toggle( flag )
      send "#{flag}=", ( send( flag ) ? false : true )
    end

    ##
    # Возвращает флаги в виде числа (битовой маски).
    # @return [Integer]
    #
    def to_i
      FlagsProxy.convert_flags_to_number @flags, @state
    end

    ##
    # Возвращает флаги в виде строки.
    # @return [String]
    #
    def to_s
      @state.map( &:to_s ).join( ", " )
    end

    ##
    # Возвращает выставленные флаги в виде строки (для отладки).
    # @return [String]
    #
    def inspect
      "<Flags: #{to_s}>"
    end

    ##
    # Form-builder требует этот метод.
    #
    def persisted?
      false
    end

    ##
    # Прикидываемся массивом.
    #
    def class
      Array
    end

    # Текущее состояние
    attr_reader :state

    ##
    # Перенаправляем все неизвестные методы на массив состояний.
    #
    def method_missing( name, *args )
      state.send name, *args
    end

    ##
    # Загружает состояние флагов из базы.
    #
    def load_state
      @state =
        if @object.new_record?
          @options[ :default ]
        else
          FlagsProxy.convert_number_to_flags @flags, @object[ @options[ :field_name ]]
        end
    end

    ##
    # Сохраненяет состояния флагов в базу.
    #
    def save_state
      @object[ @options[ :field_name ]] = self.to_i
    end

    ##
    # Установка состояния.
    # @param [Array,Hash,Fixnum] state состояние
    #
    def state=( value )
      # Состояние может массивом флагов, хешем вида { :флаг => состояние } или
      # битовой маской.
      case value
        when Array
          value.map!( &:to_sym )
          unknown_flags = value - @flags
          raise ArgumentError, "unknown flags: #{unknown_flags.inspect}" unless unknown_flags.empty?
          @state = value

        when Hash
          self.state = value.reject { |k, v| not v.to_s.to_b }.keys

        when Fixnum
          self.state = FlagsProxy.convert_number_to_flags @flags, value

        else
          raise ArgumentError, "expected Array or Fixnum. Got: #{value.inspect}"
      end
    end

    ##
    # Преобразует число (битовую маску) в массив флагов.
    #
    # @param [Array] all_flags массив со всеми возможными флагами
    # @param [Integer] number битовая маска
    # @return [Array]
    #
    def self.convert_number_to_flags( all_flags, number )
      all_flags.inject( [] ) do |result, flag|
        if number[ all_flags.index( flag )] == 1
          result << flag
        else
          result
        end
      end
    end

    ##
    # Преобразует массив флагов в число.
    #
    # @param [Array] all_flags массив со всеми возможными флагами
    # @param [Array] flags набор флагов
    # @return [Integer]
    #
    def self.convert_flags_to_number( all_flags, *flags )
      flags = ( flags.first.is_a? Array ) ? flags.first : flags

      unknown_flags = flags - all_flags
      raise ArgumentError, "unknown flags: #{unknown_flags.inspect}" unless unknown_flags.empty?

      flags.inject( 0 ) do |num, flag|
        num |= ( 1 << all_flags.index( flag ))
      end
    end
  end
end