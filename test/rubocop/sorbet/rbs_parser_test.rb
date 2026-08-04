# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Sorbet
    class RBSParserTest < ::Minitest::Test
      # `RBSParser` is a pure module over a `ProcessedSource` and comment
      # nodes; these tests exercise its public API (`rbs_signatures_before`,
      # which returns comment groups, and `return_type_range`) directly,
      # without a Cop.

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
        assert_equal(["#: (String) -> void"], sigs.first.map(&:text))
      end

      def test_signatures_before_overloads
        sigs = signatures_before("#: (String) -> void\n#: (Integer) -> void\ndef foo; end")
        assert_equal(2, sigs.size)
        assert_equal(["#: (String) -> void"], sigs[0].map(&:text))
        assert_equal(["#: (Integer) -> void"], sigs[1].map(&:text))
      end

      def test_signatures_before_continuation_lines_join
        sigs = signatures_before("#: (\n#| String name\n#| ) -> String\ndef foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: (", "#| String name", "#| ) -> String"], sigs.first.map(&:text))
      end

      def test_signatures_before_blank_line_separates
        assert_empty(signatures_before("#: (String) -> void\n\ndef foo; end"))
      end

      def test_signatures_before_climbs_send_wrappers
        sigs = signatures_before("#: -> void\nprivate def foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: -> void"], sigs.first.map(&:text))
      end

      def test_signatures_before_skips_adjacent_non_rbs_comments
        sigs = signatures_before("# before\n#: (String) -> void\ndef foo; end")
        assert_equal(1, sigs.size)
        assert_equal(["#: (String) -> void"], sigs.first.map(&:text))
      end

      def test_signatures_before_orphan_continuation_dropped
        assert_empty(signatures_before("#| orphan\ndef foo; end"))
      end

      def test_signatures_before_empty_when_no_comments
        assert_empty(signatures_before("def foo; end"))
      end

      # --- return_type_range ---

      def test_return_type_range_simple
        highlight, replace = return_type_range("#: (String) -> String\ndef foo; end")
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_return_type_range_multiline_params
        highlight, replace = return_type_range("#: (\n#| String name\n#| ) -> String\ndef foo; end")
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_return_type_range_proc_return
        highlight, replace = return_type_range("#: (String) -> ^(Integer) -> void\ndef foo; end")
        assert_equal("^(Integer)", highlight.source)
        assert_equal("^(Integer) -> void", replace.source)
      end

      def test_return_type_range_block_return
        highlight, replace = return_type_range("#: () { (?) -> untyped } -> String\ndef foo; end")
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_return_type_range_on_next_line
        highlight, replace = return_type_range("#: (String) ->\n#| String\ndef foo; end")
        assert_equal("String", highlight.source)
        assert_equal("String", replace.source)
      end

      def test_return_type_range_parenthesized_union
        highlight, replace = return_type_range("#: (String) ->\n#| (Integer | String)\ndef foo; end")
        assert_equal("Integer", highlight.source)
        assert_equal("Integer | String", replace.source)
      end

      def test_return_type_range_void_is_nil
        # `void` returns are correct; there is nothing to highlight or replace.
        assert_nil(return_type_range("#: (String) -> void\ndef foo; end"))
      end

      def test_return_type_range_nil_without_arrow
        assert_nil(return_type_range("#: (String)\ndef foo; end"))
      end

      def test_return_type_range_nil_with_empty_return
        assert_nil(return_type_range("#: (String) ->\ndef foo; end"))
      end

      # An unparenthesized union return is malformed: top-level `|` is the
      # method-overload boundary in RBS, so `() -> Integer | String` is not a
      # single method type. `require_eof: true` makes the trailing `| String`
      # a parse error, so no destructive partial correction is offered.
      def test_return_type_range_nil_for_unparenthesized_union
        assert_nil(return_type_range("#: (Integer) -> Integer | String\ndef foo; end"))
      end

      # Prefix-stripping robustness exercised through the public API: the
      # marker may carry zero or multiple spaces before/after `:`/`|`.
      def test_return_type_range_with_no_space_after_marker
        highlight, = return_type_range("#:-> String\ndef foo; end")
        assert_equal("String", highlight.source)
      end

      def test_return_type_range_with_multiple_spaces_after_marker
        highlight, = return_type_range("#  : (String) -> String\ndef foo; end")
        assert_equal("String", highlight.source)
      end

      def test_return_type_range_with_continuation_prefix_spacing
        highlight, = return_type_range("#: (String) ->\n#|   String\ndef foo; end")
        assert_equal("String", highlight.source)
      end

      private

      def signatures_before(source)
        ps = parse(source)
        RBSParser.rbs_signatures_before(ps, def_node(ps))
      end

      # Returns the `[highlight, replace]` range for the first RBS signature
      # above the method in `source`, or nil.
      def return_type_range(source)
        ps = parse(source)
        comments = RBSParser.rbs_signatures_before(ps, def_node(ps)).first
        RBSParser.return_type_range(ps, comments)
      end
    end
  end
end
