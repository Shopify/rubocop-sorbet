# frozen_string_literal: true

require "stringio"

module RuboCop
  module Cop
    module Sorbet
      # Checks that every method definition and attribute accessor has a Sorbet signature.
      #
      # It also suggest an autocorrect with placeholders so the following code:
      #
      # ```
      # def foo(a, b, c); end
      # ```
      #
      # Will be corrected as:
      #
      # ```
      # sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped)
      # def foo(a, b, c); end
      # ```
      #
      # You can configure the placeholders used by changing the following options:
      #
      # * `ParameterTypePlaceholder`: placeholders used for parameter types (default: 'T.untyped')
      # * `ReturnTypePlaceholder`: placeholders used for return types (default: 'T.untyped')
      # * `Style`: signature style to enforce - 'sig' for sig blocks, 'rbs' for RBS comments, 'both' to allow either (default: 'sig')
      class EnforceSignatures < ::RuboCop::Cop::Base
        extend AutoCorrector
        include SignatureHelp

        # @!method accessor?(node)
        def_node_matcher(:accessor?, <<-PATTERN)
          (send nil? {:attr_reader :attr_writer :attr_accessor} ...)
        PATTERN

        def on_def(node)
          check_node(node)
        end

        def on_defs(node)
          check_node(node)
        end

        def on_send(node)
          check_node(node) if accessor?(node)
        end

        def on_signature(node)
          sig_checker.on_signature(node, scope(node))
        end

        def on_new_investigation
          super
          @sig_checker = nil
          @rbs_checker = nil
        end

        def scope(node)
          return unless node.parent
          return node.parent if [:begin, :block, :class, :module].include?(node.parent.type)

          scope(node.parent)
        end

        private

        def check_node(node)
          scope = self.scope(node)
          sig_node = sig_checker.signature_node(scope)
          rbs_node = rbs_checker.signature_node(node)

          case signature_style
          when "rbs"
            # RBS style - only RBS signatures allowed
            if sig_node
              add_offense(
                sig_node,
                message: "Use RBS signature comments rather than sig blocks.",
              )
              return
            end

            unless rbs_node
              add_offense(
                node,
                message: "Each method is required to have an RBS signature.",
              ) do |corrector|
                autocorrect_with_signature_type(corrector, node, :rbs)
              end
              nil
            end
          when "both"
            # Both styles allowed - require at least one
            unless sig_node || rbs_node
              add_offense(
                node,
                message: "Each method is required to have a signature.",
              ) do |corrector|
                autocorrect_with_signature_type(corrector, node, :sig)
              end
            end
          else # "sig" (default)
            # Sig style - only sig signatures allowed
            unless sig_node
              add_offense(
                node,
                message: "Each method is required to have a sig block signature.",
              ) do |corrector|
                autocorrect_with_signature_type(corrector, node, :sig)
              end
            end
          end
        ensure
          sig_checker.clear_signature(scope)
        end

        def sig_checker
          @sig_checker ||= SigSignatureChecker.new(processed_source)
        end

        def rbs_checker
          @rbs_checker ||= RBSSignatureChecker.new(processed_source)
        end

        def autocorrect_with_signature_type(corrector, node, type)
          suggest = create_signature_suggestion(node, type)
          populate_signature_suggestion(suggest, node)
          corrector.insert_before(node, suggest.to_autocorrect)
        end

        def create_signature_suggestion(node, type)
          case type
          when :rbs
            RBSSuggestion.new(node.loc.column)
          else # :sig
            SigSuggestion.new(node.loc.column, param_type_placeholder, return_type_placeholder)
          end
        end

        def populate_signature_suggestion(suggest, node)
          if node.any_def_type?
            populate_method_definition_suggestion(suggest, node)
          elsif accessor?(node)
            populate_accessor_suggestion(suggest, node)
          end
        end

        def populate_method_definition_suggestion(suggest, node)
          node.arguments.each do |arg|
            suggest.params << arg.children.first
          end
        end

        def populate_accessor_suggestion(suggest, node)
          method = node.children[1]
          symbol = node.children[2]

          add_accessor_parameter_if_needed(suggest, symbol, method)
          set_void_return_for_writer(suggest, method)
        end

        def add_accessor_parameter_if_needed(suggest, symbol, method)
          return unless symbol && writer_or_accessor?(method)

          suggest.params << symbol.value
        end

        def set_void_return_for_writer(suggest, method)
          suggest.returns = "void" if method == :attr_writer
        end

        def writer_or_accessor?(method)
          method == :attr_writer || method == :attr_accessor
        end

        def param_type_placeholder
          cop_config["ParameterTypePlaceholder"] || "T.untyped"
        end

        def return_type_placeholder
          cop_config["ReturnTypePlaceholder"] || "T.untyped"
        end

        def allow_rbs?
          cop_config["AllowRBS"] == true
        end

        def signature_style
          config_value = cop_config["Style"]
          return config_value if config_value

          return "both" if allow_rbs?

          "sig"
        end

        class SignatureChecker
          def initialize(processed_source)
            @processed_source = processed_source
          end

          protected

          attr_reader :processed_source

          def preceding_comments(node)
            processed_source.ast_with_comments[node].select { |comment| comment.loc.line < node.loc.line }
          end
        end

        class RBSSignatureChecker < SignatureChecker
          RBS_COMMENT_REGEX = /^#\s*:.*$/

          def signature_node(node)
            node = node.parent while RuboCop::AST::SendNode === node.parent
            comments = preceding_comments(node)
            return if comments.empty?

            last_comment = comments.last
            return if last_comment.loc.line + 1 < node.loc.line

            comments.find { |comment| RBS_COMMENT_REGEX.match?(comment.text) }
          end
        end

        class SigSignatureChecker < SignatureChecker
          def initialize(processed_source)
            super(processed_source)
            @last_sig_for_scope = {}
          end

          def signature_node(scope)
            @last_sig_for_scope[scope]
          end

          def on_signature(node, scope)
            @last_sig_for_scope[scope] = node
          end

          def clear_signature(scope)
            @last_sig_for_scope[scope] = nil
          end
        end

        class SigSuggestion
          attr_accessor :params, :returns

          def initialize(indent, param_placeholder, return_placeholder)
            @params = []
            @returns = nil
            @indent = indent
            @param_placeholder = param_placeholder
            @return_placeholder = return_placeholder
          end

          def to_autocorrect
            out = StringIO.new
            out << "sig { "
            out << generate_params
            out << generate_return
            out << " }\n"
            out << " " * @indent # preserve indent for the next line
            out.string
          end

          private

          def generate_params
            return if @params.empty?

            out = StringIO.new
            out << "params("
            out << @params.map do |param|
              "#{param}: #{@param_placeholder}"
            end.join(", ")
            out << ")."
            out.string
          end

          def generate_return
            return "returns(#{@return_placeholder})" if @returns.nil?
            return @returns if @returns == "void"

            "returns(#{@returns})"
          end
        end

        class RBSSuggestion
          attr_accessor :params, :returns

          def initialize(indent)
            @params = []
            @returns = nil
            @indent = indent
          end

          def to_autocorrect
            out = StringIO.new
            out << "#: "
            out << generate_signature
            out << "\n"
            out << " " * @indent # preserve indent for the next line
            out.string
          end

          private

          def generate_signature
            param_types = @params.map { "untyped" }.join(", ")
            return_type = @returns || "untyped"

            if @params.empty?
              "() -> #{return_type}"
            else
              "(#{param_types}) -> #{return_type}"
            end
          end
        end
      end
    end
  end
end
