# frozen_string_literal: true

module TTY
  module Option
    class Formatter
      SHORT_OPT_LENGTH = 4
      NEWLINE = "\n"
      ELLIPSIS = "..."
      SPACE = " "

      # @api public
      def self.help(parameters, usage, **config)
        new(parameters, usage, **config).help
      end

      attr_reader :indentation

      DEFAULT_PARAM_DISPLAY = ->(str) { str.to_s.upcase }
      DEFAULT_ORDER = ->(params) { params.sort }

      # Create a help formatter
      #
      # @param [Parameters]
      #
      # @api public
      def initialize(parameters, usage, **config)
        @parameters = parameters
        @usage = usage
        @param_display = config.fetch(:param_display) { DEFAULT_PARAM_DISPLAY }
        @order = config.fetch(:order) { DEFAULT_ORDER }
        @indent = 2
        @indentation = " " * 2
        @sections = {
          usage: "Usage:",
          arguments: "Arguments:",
          keywords: "Keywords:",
          options: "Options:",
          env: "Environment:",
          examples: "Examples:"
        }
      end

      # A formatted help usage information
      #
      # @return [String]
      #
      # @api public
      def help
        output = []

        output << @usage.header + NEWLINE if @usage.header?

        output << (@usage.banner? ? @usage.banner : format_usage)

        if @usage.desc?
          output << NEWLINE + format_description
        end

        if @parameters.arguments.any? { |arg| arg.desc? && !arg.hidden? }
          output << NEWLINE + @sections[:arguments]
          output << format_section(:arguments, :variable)
        end

        if @parameters.keywords.any? { |kwarg| kwarg.desc? && !kwarg.hidden? }
          output << NEWLINE + @sections[:keywords]
          output << format_section(:keywords, :variable)
        end

        if @parameters.options?
          output << NEWLINE + @sections[:options]
          output << format_options
        end

        if @parameters.environments?
          output << NEWLINE + @sections[:env]
          output << format_section(:environments, :variable)
        end

        if @usage.example?
          output << NEWLINE + @sections[:examples]
          output << format_examples
        end

        if @usage.footer?
          output << NEWLINE + @usage.footer
        end

        formatted = output.join(NEWLINE)
        formatted.end_with?(NEWLINE) ? formatted : formatted + NEWLINE
      end

      private

      # Provide a default usage banner
      #
      # @api private
      def format_usage
        output = []
        output << @sections[:usage] + SPACE
        output << @usage.program
        output << " [#{@param_display.("options")}]" if @parameters.options?
        output << " [#{@param_display.("environment")}]" if @parameters.environments?
        output << " #{format_arguments_usage}" if @parameters.arguments?
        output << " #{format_keywords_usage}" if @parameters.keywords?
        output.join
      end

      # Format arguments
      #
      # @api private
      def format_arguments_usage
        return "" unless @parameters.arguments?

        @parameters.arguments.reduce([]) do |acc, arg|
          next acc if arg.hidden?

          acc << format_argument_usage(arg)
        end.join(SPACE)
      end

      # Provide an argument summary
      #
      # @api private
      def format_argument_usage(arg)
        arg_name = @param_display.(arg.variable)
        format_parameter_usage(arg, arg_name)
      end

      # Format parameter usage
      #
      # @api private
      def format_parameter_usage(param, param_name)
        args = []
        if 0 < param.arity
          args << "[" if param.optional?
          args << param_name
          (param.arity - 1).times { args << " #{param_name}" }
          args. << "]" if param.optional?
          args.join
        else
          (param.arity.abs - 1).times { args << param_name }
          args << "[#{param_name}#{ELLIPSIS}]"
          args.join(SPACE)
        end
      end

      # Format keywords usage
      #
      # @api private
      def format_keywords_usage
        return "" unless @parameters.keywords?

        @parameters.keywords.reduce([]) do |acc, kwarg|
          next acc if kwarg.hidden?

          acc << format_keyword_usage(kwarg)
        end.join(SPACE)
      end

      # Provide a keyword summary
      #
      # @api private
      def format_keyword_usage(kwarg)
        kwarg_name = @param_display.(kwarg.variable)
        conv_name = case kwarg.convert
                    when Proc, NilClass
                      kwarg_name
                    else
                      @param_display.(kwarg.convert)
                    end

        param_name = "#{kwarg_name}=#{conv_name}"
        format_parameter_usage(kwarg, param_name)
      end

      # Format a parameter section in the help display
      #
      # @return [String]
      #
      # @api private
      def format_section(parameters, variable)
        params = @parameters.public_send(parameters)
        longest_param = params.map(&variable).compact.max_by(&:length).length
        ordered_params = @order.(params)

        ordered_params.reduce([]) do |acc, param|
          next acc if param.hidden?

          acc << format_section_parameter(param, longest_param, variable)
        end.join(NEWLINE)
      end

      # Format a section parameter line
      #
      # @return [String]
      #
      # @api private
      def format_section_parameter(param, longest_param, variable)
        line = []
        param_name = param.public_send(variable).to_s

        if param.desc?
          line << format("%s%-#{longest_param}s", indentation, param_name)
          line << "  #{param.desc}"
        else
          line << format("%s%s", indentation, param_name)
        end

        if param.permit?
          line << format(" (permitted: %s)", param.permit.join(","))
        end

        if (default = format_default(param))
          line << default
        end

        line.join
      end

      # Format multiline description
      #
      # @api private
      def format_description
        format_multiline(@usage.desc, "")
      end

      # Returns all the options formatted to fit 80 columns
      #
      # @return [String]
      #
      # @api private
      def format_options
        return "" if @parameters.options.empty?

        longest_option = @parameters.options.map(&:long)
                                    .compact.max_by(&:length).length
        any_short = @parameters.options.map(&:short).compact.any?
        ordered_options = @order.(@parameters.options)

        ordered_options.reduce([]) do |acc, option|
          next acc if option.hidden?
          acc << format_option(option, longest_option, any_short)
        end.join(NEWLINE)
      end

      # Format an option
      #
      # @api private
      def format_option(option, longest_length, any_short)
        line = []

        if any_short
          short_option = option.short? ? option.short_name : SPACE
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
          line << format("%-#{longest_length}s", SPACE)
        end

        if option.desc?
          line << "   #{option.desc}"
        end

        if option.permit?
          line << format(" (permitted: %s)", option.permit.join(","))
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

      # Format examples section
      #
      # @api private
      def format_examples
        format_multiline(@usage.example, indentation)
      end

      # Format multiline content
      #
      # @api private
      def format_multiline(lines, indent)
        last_index = lines.size - 1
        lines.map.with_index do |line, i|
          line.map do |part|
            part.split(NEWLINE).map { |p| indent + p }.join(NEWLINE)
          end.join(NEWLINE) + (last_index != i ? NEWLINE : "")
        end.join(NEWLINE)
      end
    end # Formatter
  end # Option
end # TTY
