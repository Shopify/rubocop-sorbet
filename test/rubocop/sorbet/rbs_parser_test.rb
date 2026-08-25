# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Sorbet
    class RBSParserTest < ::Minitest::Test
      # `RBSParser` is a pure module over a `ProcessedSource` and comment
      # nodes; these tests exercise its public APIs directly without a Cop.

      def parse(source)
        RuboCop::ProcessedSource.new(source, 3.4)
      end

      # First `def`/`defs` node in the source, descending through send
      # wrappers (`private def foo; end`) and `begin` bodies.
      def def_node(ps)
        ast = ps.ast
        return ast if ast&.type?(:def, :defs)

        ast&.each_node(:def, :defs)&.first
      end

      # --- rbs_signatures_before ---

      def test_signatures_before_single_signature
        sigs = signatures_before("#: (String) -> void\ndef foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: (String) -> void"], sigs.first.comments.map(&:text))
      end

      def test_signatures_before_overloads
        sigs = signatures_before("#: (String) -> void\n#: (Integer) -> void\ndef foo; end")
        assert_equal(2, sigs.size)
        assert_equal(["#: (String) -> void"], sigs[0].comments.map(&:text))
        assert_equal(["#: (Integer) -> void"], sigs[1].comments.map(&:text))
      end

      def test_signatures_before_continuation_lines_join
        sigs = signatures_before("#: (\n#| String name\n#| ) -> String\ndef foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: (", "#| String name", "#| ) -> String"], sigs.first.comments.map(&:text))
      end

      def test_signatures_before_blank_line_separates
        assert_empty(signatures_before("#: (String) -> void\n\ndef foo; end"))
      end

      def test_signatures_before_climbs_send_wrappers
        sigs = signatures_before("#: -> void\nprivate def foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: -> void"], sigs.first.comments.map(&:text))
      end

      def test_signatures_before_skips_adjacent_non_rbs_comments
        sigs = signatures_before("# before\n#: (String) -> void\ndef foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: (String) -> void"], sigs.first.comments.map(&:text))
      end

      def test_signatures_before_orphan_continuation_dropped
        assert_empty(signatures_before("#| orphan\ndef foo; end"))
      end

      def test_signatures_before_empty_when_no_comments
        assert_empty(signatures_before("def foo; end"))
      end

      # --- rbs_annotation_after ---

      def test_annotation_after_returns_comment_and_text
        comment, annotation = annotation_after('GREETING = "hello" #: String')

        assert_equal("#: String", comment.text)
        assert_equal("String", annotation)
      end

      def test_annotation_after_handles_multiline_expression
        _comment, annotation = annotation_after(<<~RUBY)
          NAMES = [
            "alice",
            "bob",
          ] #: Array[String]
        RUBY

        assert_equal("Array[String]", annotation)
      end

      def test_annotation_after_rejects_non_rbs_comment
        assert_nil(annotation_after('GREETING = "hello" # String'))
      end

      def test_annotation_after_rejects_comment_separated_by_code
        assert_nil(annotation_after('GREETING = "hello"; nil #: String'))
      end

      # --- Signature#return_type / return_type_range / void? ---

      def test_signature_return_type_simple
        sig = signature("#: (String) -> String\ndef foo; end")
        assert_equal("String", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
        refute(sig.void?)
      end

      def test_signature_return_type_multiline_params
        sig = signature("#: (\n#| String name\n#| ) -> String\ndef foo; end")
        assert_equal("String", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_signature_return_type_proc_return
        sig = signature("#: (String) -> ^(Integer) -> void\ndef foo; end")
        assert_equal("^(Integer) -> void", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("^(Integer)", highlight.source)
        assert_equal("^(Integer) -> void", replace.source)
      end

      def test_signature_return_type_block_return
        sig = signature("#: () { (?) -> untyped } -> String\ndef foo; end")
        assert_equal("String", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_signature_return_type_on_next_line
        sig = signature("#: (String) ->\n#| String\ndef foo; end")
        assert_equal("String", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_signature_return_type_multiline_union
        sig = signature("#: (String) ->\n#| Integer |\n#| String\ndef foo; end")
        assert_equal("Integer | String", sig.return_type)
        highlight, replace = sig.return_type_range
        assert_equal("Integer", highlight.source)
        assert_equal("Integer |\n#| String", replace.source)
      end

      def test_signature_void_return
        sig = signature("#: (String) -> void\ndef foo; end")
        assert_equal("void", sig.return_type)
        assert(sig.void?)
        highlight, replace = sig.return_type_range
        assert_equal("void", highlight.source)
        assert_equal("void", replace.source)
      end

      def test_signature_return_type_nil_without_arrow
        sig = signature("#: (String)\ndef foo; end")
        assert_nil(sig.return_type)
        assert_nil(sig.return_type_range)
        refute(sig.void?)
      end

      def test_signature_return_type_nil_with_empty_return
        sig = signature("#: (String) ->\ndef foo; end")
        assert_nil(sig.return_type)
        assert_nil(sig.return_type_range)
      end

      # Whitespace is allowed after the `#:`/`#|` marker, but Sorbet requires
      # the marker itself to be contiguous.
      def test_signature_return_type_with_no_space_after_marker
        sig = signature("#:-> void\ndef foo; end")
        assert_equal("void", sig.return_type)
        assert(sig.void?)
      end

      def test_signatures_before_rejects_space_within_marker
        assert_empty(signatures_before("#  : (String) -> String\ndef foo; end"))
      end

      def test_signature_return_type_with_continuation_prefix_spacing
        sig = signature("#: (String) ->\n#|   String\ndef foo; end")
        assert_equal("String", sig.return_type)
        highlight, = sig.return_type_range
        assert_equal("String", highlight.source)
      end

      def test_signatures_before_rejects_space_within_continuation_marker
        sig = signature("#: (String) ->\n# | String\ndef foo; end")
        assert_nil(sig.return_type)
      end

      # --- rbs_comment? ---

      def test_rbs_comment_matches_signature_marker
        assert(RBSParser.rbs_comment?(comment("#: (String) -> void")))
      end

      def test_rbs_comment_matches_continuation_marker
        assert(RBSParser.rbs_comment?(comment("#| ) -> void")))
      end

      def test_rbs_comment_rejects_plain_comment
        refute(RBSParser.rbs_comment?(comment("# plain comment")))
      end

      def test_rbs_comment_rejects_space_within_marker
        refute(RBSParser.rbs_comment?(comment("# : (String) -> void")))
      end

      # --- rbs_tokens ---

      def test_rbs_tokens_splits_signatures
        tokens = RBSParser.rbs_tokens(comment("#: (String) -> void"))

        assert_equal(
          [[:pLPAREN, "("], [:tUIDENT, "String"], [:pRPAREN, ")"], [:pARROW, "->"], [:kVOID, "void"]],
          tokens.map { |token| [token.type, token.location.source] },
        )
      end

      def test_rbs_tokens_splits_continued_signatures
        tokens = RBSParser.rbs_tokens(comment("#| ) -> String"))

        assert_equal(
          [[:pRPAREN, ")"], [:pARROW, "->"], [:tUIDENT, "String"]],
          tokens.map { |token| [token.type, token.location.source] },
        )
      end

      def test_rbs_tokens_splits_annotations
        tokens = RBSParser.rbs_tokens(comment("values = [] #: Array[String]"))

        assert_equal(
          [[:tUIDENT, "Array"], [:pLBRACKET, "["], [:tUIDENT, "String"], [:pRBRACKET, "]"]],
          tokens.map { |token| [token.type, token.location.source] },
        )
      end

      def test_rbs_tokens_splits_assertions
        tokens = RBSParser.rbs_tokens(comment("values = result #: as Hash[Symbol, Integer]"))

        assert_equal(
          [
            [:kAS, "as"],
            [:tUIDENT, "Hash"],
            [:pLBRACKET, "["],
            [:tUIDENT, "Symbol"],
            [:pCOMMA, ","],
            [:tUIDENT, "Integer"],
            [:pRBRACKET, "]"],
          ],
          tokens.map { |token| [token.type, token.location.source] },
        )
      end

      def test_rbs_tokens_splits_type_aliases
        tokens = RBSParser.rbs_tokens(comment("#: type user_id = Integer"))

        assert_equal(
          [[:kTYPE, "type"], [:tLIDENT, "user_id"], [:pEQ, "="], [:tUIDENT, "Integer"]],
          tokens.map { |token| [token.type, token.location.source] },
        )
      end

      def test_rbs_tokens_empty_for_non_rbs_comment
        assert_empty(RBSParser.rbs_tokens(comment("# plain comment")))
      end

      def test_rbs_tokens_positions_match_their_place_in_comment
        comment = comment("values = [] #: Hash[Symbol, Integer]")

        RBSParser.rbs_tokens(comment).each do |token|
          assert_equal(token.location.source, comment.text[token.location.start_pos...token.location.end_pos])
        end
      end

      private

      def comment(source)
        parse(source).comments.first
      end

      def signatures_before(source)
        ps = parse(source)
        RBSParser.rbs_signatures_before(ps, def_node(ps))
      end

      def annotation_after(source)
        ps = parse(source)
        node = ps.ast
        node = node.each_node(:casgn).first unless node.casgn_type?
        RBSParser.rbs_annotation_after(ps, node)
      end

      def signature(source)
        signatures_before(source).first
      end
    end
  end
end
