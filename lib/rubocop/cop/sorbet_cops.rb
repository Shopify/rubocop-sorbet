# frozen_string_literal: true

require_relative "sorbet/mixin/target_sorbet_version"
require_relative "sorbet/mixin/t_enum"
require_relative "sorbet/mixin/signature_help"

require_relative "sorbet/binding_constant_without_type_alias"
require_relative "sorbet/constants_from_strings"
require_relative "sorbet/forbid_superclass_const_literal"
require_relative "sorbet/forbid_include_const_literal"
require_relative "sorbet/forbid_type_aliased_shapes"
require_relative "sorbet/forbid_untyped_struct_props"
require_relative "sorbet/implicit_conversion_method"
require_relative "sorbet/callback_conditionals_binding"
require_relative "sorbet/forbid_t_enum"
require_relative "sorbet/forbid_t_struct"
require_relative "sorbet/forbid_t_unsafe"
require_relative "sorbet/forbid_t_untyped"
require_relative "sorbet/redundant_extend_t_sig"
require_relative "sorbet/refinement"
require_relative "sorbet/type_alias_name"
require_relative "sorbet/obsolete_strict_memoization"
require_relative "sorbet/buggy_obsolete_strict_memoization"

require_relative "sorbet/rbi/forbid_extend_t_sig_helpers_in_shims"
require_relative "sorbet/rbi/forbid_rbi_outside_of_allowed_paths"
require_relative "sorbet/rbi/single_line_rbi_class_module_definitions"

require_relative "sorbet/rbi_versioning/gem_version_annotation_helper"
require_relative "sorbet/rbi_versioning/valid_gem_version_annotations"

require_relative "sorbet/signatures/allow_incompatible_override"
require_relative "sorbet/signatures/checked_true_in_signature"
require_relative "sorbet/signatures/empty_line_after_sig"
require_relative "sorbet/signatures/enforce_signatures"
require_relative "sorbet/signatures/forbid_sig"
require_relative "sorbet/signatures/forbid_sig_with_runtime"
require_relative "sorbet/signatures/forbid_sig_without_runtime"
require_relative "sorbet/signatures/keyword_argument_ordering"
require_relative "sorbet/signatures/signature_build_order"
require_relative "sorbet/signatures/void_checked_tests"

require_relative "sorbet/sigils/valid_sigil"
require_relative "sorbet/sigils/has_sigil"
require_relative "sorbet/sigils/ignore_sigil"
require_relative "sorbet/sigils/false_sigil"
require_relative "sorbet/sigils/true_sigil"
require_relative "sorbet/sigils/strict_sigil"
require_relative "sorbet/sigils/strong_sigil"
require_relative "sorbet/sigils/enforce_sigil_order"
require_relative "sorbet/sigils/enforce_single_sigil"

require_relative "sorbet/t_enum/forbid_comparable_t_enum"
require_relative "sorbet/t_enum/multiple_t_enum_values"

require_relative "sorbet/mutable_constant_sorbet_aware_behaviour"
