# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Sorbet
    class RBSParserTest < ::Minitest::Test
      # `RBSParser` is a pure module over a `ProcessedSource` and comment
      # nodes; these tests exercise its public API (`rbs_signatures_before`
      # and the `Signature` objects it returns) directly, without a Cop.

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

      private

      def signatures_before(source)
        ps = parse(source)
        RBSParser.rbs_signatures_before(ps, def_node(ps))
      end

      def signature(source)
        signatures_before(source).first
      end
    end
  end
end
