# frozen_string_literal: true

module TTY
  module Option
    class Formatter
      SHORT_OPT_LENGTH = 4
      NEWLINE = "\n"
      ELLIPSIS = "..."

      # @api public
      def self.help(parameters, usage)
        new(parameters, usage).help
      end

      # Create a help formatter
      #
      # @param [Parameters]
      #
      # @api public
      def initialize(parameters, usage)
        @parameters = parameters
        @usage = usage
        @indent = 2
      end

      # A formatted help usage information
      #
      # @return [String]
      #
      # @api public
      def help
        output = []

        output << @usage.header + NEWLINE if @usage.header?

        output << (@usage.banner? ? @usage.banner : format_usage) + NEWLINE

        if @usage.desc?
          output << @usage.desc + NEWLINE
        end

        if @parameters.options?
          output << "Options:"
          output << format_options
        end

        if @parameters.environments?
          output << NEWLINE + "Environment:"
          output << format_environment
        end

        output << @usage.footer + NEWLINE if @usage.footer?

        formatted = output.join(NEWLINE)
        formatted.end_with?(NEWLINE) ? formatted : formatted + NEWLINE
      end

      private

      # @api private
      def format_usage
        output = []
        output << "Usage: "
        output << @usage.program
        output << " [OPTIONS]" if @parameters.options?
        output << " [ENVIRONMENT]" if @parameters.environments?
        output << " #{format_arguments}" if @parameters.arguments?
        output.join
      end

      # @api private
      def format_arguments
        return "" unless @parameters.arguments?

        @parameters.arguments.reduce([]) do |acc, arg|
          arg_name = arg.name.to_s.upcase
          if 0 < arg.arity
            args = []
            args << "[" if arg.optional?
            args << arg_name
            (arg.arity - 1).times { args << " #{arg_name}" }
            args << "]" if arg.optional?
            acc << args.join
          else
            (arg.arity.abs - 1).times { acc << arg_name }
            acc << "[#{arg_name}#{ELLIPSIS}]"
          end
          acc
        end.join(" ")
      end

      # Returns all the options formatted to fit 80 columns
      #
      # @return [String]
      #
      # @api private
      def format_options
        return "" if @parameters.options.empty?

        output = []
        longest_option = @parameters.options.map(&:long)
                                    .compact.max_by(&:length).length
        any_short = @parameters.options.map(&:short).compact.any?
        ordered_options = @parameters.options.sort

        ordered_options.each do |option|
          output << format_option(option, longest_option, any_short)
        end

        output.join(NEWLINE)
      end

      # Format an option
      #
      # @api private
      def format_option(option, longest_length, any_short)
        line = []

        if any_short
          short_option = option.short? ? option.short_name : " "
          line << format("%#{SHORT_OPT_LENGTH}s", short_option)
        end

        # short & long option separator
        line << ((option.short? && option.long?) ? ", " : "  ")

        if option.long?
          if option.desc?
            line << format("%-#{longest_length}s", option.long)
          else
            line << option.long
          end
        else
          line << format("%-#{longest_length}s", " ")
        end

        if option.desc?
          line << "   #{option.desc}"
        end

        if (default = format_default(option))
          line << default
        end

        line.join
      end

      # Format default value
      #
      # @api private
      def format_default(param)
        return if !param.default? || [true, false].include?(param.default)

        if param.default.is_a?(String)
          format(" (default %p)", param.default)
        else
          format(" (default %s)", param.default)
        end
      end

      # @api private
      def format_environment
        output = []
        longest_var = @parameters.environments.map(&:variable)
                                 .compact.max_by(&:length).length
        ordered_envs = @parameters.environments.sort

        ordered_envs.each do |env|
          output << format_env(env, longest_var)
        end

        output.join(NEWLINE)
      end

      # @api private
      def format_env(env, longest_var)
        line = []

        if env.desc?
          line << format("%s%-#{longest_var}s", " " * @indent, env.variable.upcase)
          line << "   #{env.desc}"
        else
          line << format("%s%s", " " * @indent, env.variable.upcase)
        end

        if (default = format_default(env))
          line << default
        end

        line.join
      end
    end # Formatter
  end # Option
end # TTY