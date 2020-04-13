# frozen_string_literal: true

module TTY
  module Option
    class ErrorAggregator
      # Collected errors
      attr_reader :errors

      def initialize(errors = {}, **config)
        @errors = errors
        @raise_if_missing = config.fetch(:raise_if_missing) { true }
      end

      # Record or raise an error
      #
      # @param [TTY::Option::Error] error
      # @param [String] message
      # @param [TTY::Option::Parameter] param
      #
      # @api public
      def call(error, message, param = nil)
        is_class = error.is_a?(Class)

        if @raise_if_missing
          if is_class
            raise error, message
          else
            raise error
          end
        end

        type_name = is_class ? error.name : error.class.name
        type_key = type_name.to_s.split("::").last
                            .gsub(/([a-z]+)([A-Z])/, "\\1_\\2")
                            .downcase.to_sym

        if param
          (@errors[param.name] ||= {}).merge!(type_key => message)
        else
          (@errors[:messages] ||= []) << { type_key => message }
        end
      end
    end # ErrorAggregator
  end # Option
end # TTY