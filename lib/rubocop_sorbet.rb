# frozen_string_literal: true

require_relative 'rubocop/cop/sorbet/binding_constants_without_type_alias'
require_relative 'rubocop/cop/sorbet/constants_from_strings'
require_relative 'rubocop/cop/sorbet/forbid_superclass_const_literal'
require_relative 'rubocop/cop/sorbet/forbid_include_const_literal'
require_relative 'rubocop/cop/sorbet/prefer_sorbet_over_contracts'

require_relative 'rubocop/cop/sorbet/signatures/allow_incompatible_override'
require_relative 'rubocop/cop/sorbet/signatures/checked_true_in_signature'
require_relative 'rubocop/cop/sorbet/signatures/keyword_argument_ordering'
require_relative 'rubocop/cop/sorbet/signatures/parameters_ordering_in_signature'
require_relative 'rubocop/cop/sorbet/signatures/signature_build_order'
require_relative 'rubocop/cop/sorbet/signatures/enforce_signatures'

require_relative 'rubocop/cop/sorbet/sigils/valid_sigil'
require_relative 'rubocop/cop/sorbet/sigils/has_sigil'
require_relative 'rubocop/cop/sorbet/sigils/ignore_sigil'
require_relative 'rubocop/cop/sorbet/sigils/false_sigil'
require_relative 'rubocop/cop/sorbet/sigils/true_sigil'
require_relative 'rubocop/cop/sorbet/sigils/strict_sigil'
require_relative 'rubocop/cop/sorbet/sigils/strong_sigil'
require_relative 'rubocop/cop/sorbet/sigils/enforce_sigil_order'
