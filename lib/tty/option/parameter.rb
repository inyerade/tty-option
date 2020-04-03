# frozen_string_literal: true

require_relative "arity_dsl"

module TTY
  module Option
    class Parameter
      include ArityDSL

      def self.create(name, **settings, &block)
        new(name, **settings, &block)
      end

      attr_reader :name

      attr_reader :settings

      def initialize(name, **settings, &block)
        check_settings!(settings)
        @name = name
        @settings = settings

        arity(@settings[:arity]) if @settings.key?(:arity)
        validate(@settings[:validate]) if @settings.key?(:validate)

        instance_eval(&block) if block_given?
      end

      def check_settings!(settings)
        if settings.key?(:arity)
          check_arity(settings[:arity])
        end
        if settings.key?(:validate)
          check_validation(settings[:validate])
        end
      end

      def default_arity
        1
      end

      def arity(value = (not_set = true))
        if not_set
          @settings.fetch(:arity) { default_arity }
        else
          @settings[:arity] = check_arity(value)
        end
      end

      # Check if multiple occurrences are allowed
      #
      # @return [Boolean]
      #
      # @api public
      def multiple?
        arity < 0 || 1 < arity.abs
      end

      def convert(value = (not_set = true))
        if not_set
          @settings[:convert]
        else
          @settings[:convert] = value
        end
      end

      def convert?
        @settings.key?(:convert) && !@settings[:convert].nil?
      end

      def default(value = (not_set = true))
        if not_set
          @settings[:default]
        else
          @settings[:default] = value
        end
      end
      alias defaults default

      def default?
        @settings.key?(:default) && !@settings[:default].nil?
      end

      def optional
        @settings[:required] = false
      end

      def optional?
        !required?
      end

      def required
        @settings[:required] = true
      end

      def required?
        @settings.fetch(:required) { true }
      end

      def validate(value = (not_set = true))
        if not_set
          @settings[:validate]
        else
          @settings[:validate] = check_validation(value)
        end
      end

      def validate?
        @settings.key?(:validate) && !@settings[:validate].nil?
      end

      def to_sym
        self.class.name.to_s.split(/::/).last.downcase.to_sym
      end

      def to_h
        @settings.dup
      end

      private

      # @api private
      def check_arity(value)
        if value.nil?
          raise InvalidArity, "expects an integer value"
        end

        if value.to_s =~ %r{\*|any}
          value = -1
        end
        value = value.to_i

        if value.zero?
          raise InvalidArity, "cannot be zero"
        end
        value
      end

      # @api private
      def check_validation(value)
        case value
        when NilClass
          raise TTY::Option::InvalidValidation,
                "expects a Proc or a Regexp value"
        when Proc
          value
        when Regexp, String
          Regexp.new(value.to_s)
        else
          raise TTY::Option::InvalidValidation,
                "only accepts a Proc or a Regexp type"
        end
      end
    end # Parameter
  end # Option
end # TTY
