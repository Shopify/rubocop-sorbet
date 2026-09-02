# frozen_string_literal: true

require "rbi"
require "spoom"

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
      # * `AutocorrectStyle`: signature style to use when autocorrecting - 'sig' for sig blocks, 'rbs' for RBS comments (default: 'sig'). Only used when `Style` is 'both'.
      class EnforceSignatures < ::RuboCop::Cop::Base
        include RangeHelp
        extend AutoCorrector
        include SignatureHelp

        VALID_STYLES = ["sig", "rbs", "both"].freeze
        VALID_AUTOCORRECT_STYLES = ["sig", "rbs"].freeze

        # Represents a method parameter with its name and AST node kind.
        # @kind is the RuboCop AST node type (:arg, :optarg, :restarg, :kwarg,
        # :kwoptarg, :kwrestarg, :forward_arg, :blockarg).
        Param = Struct.new(:name, :kind)

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
          sig_nodes = sig_checker.signature_nodes(scope)
          rbs_signatures = rbs_checker.signatures(node)
          rbs_signatures = rbs_checker.signatures(sig_nodes.first) if rbs_signatures.empty? && !sig_nodes.empty?

          case signature_style
          when "rbs"
            # RBS style - only RBS signatures allowed
            unless sig_nodes.empty?
              add_offense(sig_nodes.first, message: "Use RBS signature comments rather than sig blocks.") do |corrector|
                if rbs_signatures.empty?
                  autocorrect_sigs_to_rbs(corrector, node, sig_nodes)
                else
                  remove_sigs(corrector, sig_nodes)
                end
              end
              return
            end

            if rbs_signatures.empty?
              add_offense(node, message: "Each method is required to have an RBS signature.") do |corrector|
                autocorrect_with_signature_type(corrector, node, "rbs")
              end
            end
          when "both"
            # Both styles allowed - require at least one
            if sig_nodes.empty? && rbs_signatures.empty?
              add_offense(node, message: "Each method is required to have a signature.") do |corrector|
                autocorrect_with_signature_type(corrector, node, autocorrect_style)
              end
            end
          else # "sig" (default)
            # Sig style - only sig signatures allowed
            if rbs_signatures.any?
              first_comment = rbs_signatures.first.comments.first
              add_offense(first_comment, message: "Use sig block signatures rather than RBS signature comments.") do |corrector|
                if sig_nodes.empty?
                  autocorrect_rbs_to_sigs(corrector, node, rbs_signatures)
                else
                  remove_rbs(corrector, rbs_signatures)
                end
              end
            elsif sig_nodes.empty?
              add_offense(node, message: "Each method is required to have a sig block signature.") do |corrector|
                autocorrect_with_signature_type(corrector, node, "sig")
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
          target = leftmost_send_ancestor(node)
          suggest = create_signature_suggestion(target, type)
          populate_signature_suggestion(suggest, node)

          corrector.insert_before(target, suggest.to_autocorrect)
        end

        def create_signature_suggestion(node, type)
          suggestion_class = type == "rbs" ? RBSSuggestion : SigSuggestion
          suggestion_class.new(node.loc.column, param_type_placeholder, return_type_placeholder)
        end

        def autocorrect_rbs_to_sigs(corrector, node, rbs_signatures)
          comments = rbs_signatures.flat_map(&:comments)
          range = rbs_correction_range(comments)
          rbs_source = range.source.lines.map(&:lstrip).join
          translated = translate_rbs_to_sigs("#{rbs_source}\n#{node.source}")
          replacement = translated_signature_prefix(translated).rstrip
          indent = " " * range.column
          corrector.replace(range, replacement.gsub("\n", "\n#{indent}"))
        end

        def remove_rbs(corrector, rbs_signatures)
          comments = rbs_signatures.flat_map(&:comments)
          range = range_by_whole_lines(rbs_correction_range(comments), include_final_newline: true)
          corrector.remove(range)
        end

        def autocorrect_sigs_to_rbs(corrector, node, sig_nodes)
          range = sig_correction_range(sig_nodes)
          sig_source = normalize_runtime_sig_receivers(range, sig_nodes)
          translated = translate_sigs_to_rbs("#{sig_source}\n#{node.source}")
          replacement = translated_signature_prefix(translated, reject_sig: true)
          return unless replacement

          corrector.replace(range, replacement.rstrip)
        end

        def normalize_runtime_sig_receivers(range, sig_nodes)
          source = range.source.dup
          sig_nodes.reverse_each do |sig_node|
            next unless sig_with_runtime?(sig_node)

            send_node = sig_node.send_node
            receiver_start = send_node.receiver.source_range.begin_pos - range.begin_pos
            selector_start = send_node.loc.selector.begin_pos - range.begin_pos
            source[receiver_start...selector_start] = ""
          end
          source
        end

        def remove_sigs(corrector, sig_nodes)
          range = range_by_whole_lines(sig_correction_range(sig_nodes), include_final_newline: true)
          corrector.remove(range)
        end

        def sig_correction_range(sig_nodes)
          sig_nodes.first.source_range.with(end_pos: sig_nodes.last.source_range.end_pos)
        end

        def rbs_correction_range(comments)
          first_comment = comments.first
          expected_line = first_comment.loc.line
          processed_source.comments.reverse_each do |comment|
            next if comment.loc.line >= first_comment.loc.line
            break unless comment.loc.line + 1 == expected_line && comment.text.start_with?("# @")

            first_comment = comment
            expected_line = comment.loc.line
          end

          first_comment.source_range.with(end_pos: comments.last.source_range.end_pos)
        end

        def translated_signature_prefix(translated, reject_sig: false)
          translated_source = RuboCop::ProcessedSource.new(
            translated,
            [processed_source.ruby_version, 3.3].max,
            parser_engine: processed_source.parser_engine,
          )
          return if reject_sig && translated_source.ast&.each_node&.any? { |child| signature?(child) }

          signable_node = translated_source.ast&.each_node&.find do |child|
            child.any_def_type? || accessor?(child)
          end
          raise "Spoom translation did not produce a method or accessor" unless signable_node

          target = leftmost_send_ancestor(signable_node)
          translated.byteslice(0, target.source_range.begin_pos)
        end

        def translate_sigs_to_rbs(input)
          ::Spoom::Sorbet::Translate.sorbet_sigs_to_rbs_comments(
            input,
            file: processed_source.file_path,
            positional_names: false,
          )
        end

        def translate_rbs_to_sigs(input)
          ::Spoom::Sorbet::Translate::RBSCommentsToSorbetSigs::HumanReadableTranslator.new(
            input,
            file: processed_source.file_path,
          ).rewrite
        end

        def leftmost_send_ancestor(node)
          ancestor = node
          ancestor = ancestor.parent while ancestor.parent&.send_type?
          ancestor
        end

        def populate_signature_suggestion(suggest, node)
          if node.any_def_type?
            populate_method_definition_suggestion(suggest, node)
          elsif accessor?(node)
            populate_accessor_suggestion(suggest, node)
          end
        end

        def populate_method_definition_suggestion(suggest, node)
          suggest.returns = "void" if instance_initialize?(node)

          node.arguments.each do |arg|
            suggest.params << Param.new(arg.children.first, arg.type)
          end
        end

        def instance_initialize?(node)
          node.def_type? && node.method?(:initialize) && !in_sclass_context?(node)
        end

        def in_sclass_context?(node)
          parent = node.parent
          while parent
            return true if parent.sclass_type?
            return false if parent.type?(:class, :module)

            parent = parent.parent
          end
          false
        end

        def populate_accessor_suggestion(suggest, node)
          method = node.children[1]
          symbol = node.children[2]

          suggest.accessor = method
          add_accessor_parameter_if_needed(suggest, symbol, method)
          set_void_return_for_writer(suggest, method)
        end

        def add_accessor_parameter_if_needed(suggest, symbol, method)
          return unless symbol && writer_or_accessor?(method)

          suggest.params << Param.new(symbol.value, :arg)
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
          if config_value
            unless VALID_STYLES.include?(config_value)
              raise ArgumentError, "Invalid Style option: '#{config_value}'. Valid options are: #{VALID_STYLES.join(", ")}"
            end

            return config_value
          end

          return "both" if allow_rbs?

          "sig"
        end

        def autocorrect_style
          config_value = cop_config["AutocorrectStyle"] || "sig"
          unless VALID_AUTOCORRECT_STYLES.include?(config_value)
            raise ArgumentError, "Invalid AutocorrectStyle option: '#{config_value}'. Valid options are: #{VALID_AUTOCORRECT_STYLES.join(", ")}"
          end

          config_value
        end

        class SignatureChecker
          def initialize(processed_source)
            @processed_source = processed_source
          end

          protected

          attr_reader :processed_source
        end

        class RBSSignatureChecker < SignatureChecker
          def signatures(node)
            ::RuboCop::Sorbet::RBSParser.rbs_signatures_before(processed_source, node)
          end
        end

        class SigSignatureChecker < SignatureChecker
          EMPTY_SIGNATURES = [].freeze

          def initialize(processed_source)
            super(processed_source)
            @signatures_for_scope = {}
          end

          def signature_nodes(scope)
            @signatures_for_scope.fetch(scope, EMPTY_SIGNATURES)
          end

          def on_signature(node, scope)
            (@signatures_for_scope[scope] ||= []) << node
          end

          def clear_signature(scope)
            @signatures_for_scope.delete(scope)
          end
        end

        class RBSSuggestion
          attr_accessor :params, :accessor

          def initialize(indent, param_placeholder, return_placeholder)
            @params = []
            @returns = nil
            @accessor = nil
            @indent = indent
            @param_type = RBI::Type.parse_string(param_placeholder)
            @return_type = RBI::Type.parse_string(return_placeholder)
          end

          def returns=(value)
            @returns = value == "void" ? RBI::Type.void : value
          end

          def to_autocorrect
            signature = if accessor
              type = accessor == :attr_writer ? @param_type : @return_type
              "#: #{type.rbs_string}"
            else
              method = RBI::Method.new("f")
              sig = RBI::Sig.new(return_type: @returns || @return_type)
              params.each do |param|
                rbi_params(param).each do |method_param, sig_param|
                  method << method_param
                  sig << RBI::SigParam.new(sig_param, @param_type) if sig_param
                end
              end
              method.sigs << sig
              "#: #{method.rbs_string(positional_names: false).delete_prefix("def f: ").delete_suffix("\n")}"
            end

            "#{signature}\n#{" " * @indent}"
          end

          private

          def rbi_params(param)
            case param.kind
            when :arg
              [[RBI::ReqParam.new(param.name), param.name]]
            when :optarg
              [[RBI::OptParam.new(param.name, "nil"), param.name]]
            when :restarg
              [[RBI::RestParam.new(param.name), param.name || "*"]]
            when :kwarg
              [[RBI::KwParam.new(param.name), param.name]]
            when :kwoptarg
              [[RBI::KwOptParam.new(param.name, "nil"), param.name]]
            when :kwrestarg
              [[RBI::KwRestParam.new(param.name), param.name || "**"]]
            when :blockarg
              [[RBI::BlockParam.new(param.name), param.name || "&"]]
            when :forward_arg
              [
                [RBI::RestParam.new(nil), "*"],
                [RBI::KwRestParam.new(nil), "**"],
                [RBI::BlockParam.new(nil), "&"],
              ]
            when :nokey, :kwnilarg
              [[RBI::NoKwParam.new, nil]]
            else
              [[RBI::ReqParam.new("untyped"), "untyped"]]
            end
          end
        end

        class SigSuggestion
          attr_accessor :params, :returns, :accessor

          def initialize(indent, param_placeholder, return_placeholder)
            @params = []
            @returns = nil
            @indent = indent
            @param_placeholder = param_placeholder
            @return_placeholder = return_placeholder
          end

          def to_autocorrect
            "sig { #{generate_params}#{generate_return} }\n#{" " * @indent}"
          end

          private

          def generate_params
            return "" if @params.empty?

            param_list = @params.map { |param| "#{param.name}: #{@param_placeholder}" }.join(", ")
            "params(#{param_list})."
          end

          def generate_return
            if @returns.nil?
              "returns(#{@return_placeholder})"
            elsif @returns == "void"
              "void"
            else
              "returns(#{@returns})"
            end
          end
        end
      end
    end
  end
end
