# frozen_string_literal: true

module Sorbet
  class SorbetFromContractService
    class AutoCorrectError < StandardError; end
    CONTRACT_PATTERN = RuboCop::NodePattern.new("$(send _ :Contract $... (:hash (:pair $_ $_)))")

    EXTEND_T_SIG_PATTERN = RuboCop::NodePattern.new("(send _ :extend (const (const _ :T) :Sig))")

    CONST_PATTERN = RuboCop::NodePattern.new("(const {nil? (cbase)} $_)")
    TWO_CONST_PATTERN = RuboCop::NodePattern.new("(const (const {nil? (cbase)} $_) $_)")
    THREE_CONST_PATTERN = RuboCop::NodePattern.new("(const (const (const {nil? (cbase)} $_) $_) $_)")
    FOUR_CONST_PATTERN = RuboCop::NodePattern.new("(const (const (const (const {nil? (cbase)} $_) $_) $_) $_)")
    SEND_PATTERN = RuboCop::NodePattern.new("(send $_ _ $...)")
    NIL_PATTERN = RuboCop::NodePattern.new("nil")
    SELF_PATTERN = RuboCop::NodePattern.new("self")
    HASH_PATTERN = RuboCop::NodePattern.new("(hash $...)")
    PAIR_MATCHER = RuboCop::NodePattern.new("(pair ({sym str} $_) $_)")
    CONST_PAIR_MATCHER = RuboCop::NodePattern.new("(hash (pair (const {nil? (cbase)} $_) (const {nil? (cbase)} $_)))")
    CONTRACT_ARGS_PATTERN = RuboCop::NodePattern.new("({arg optarg blockarg kwoptarg kwarg} $_ ...)")
    TUPLE_PATTERN = RuboCop::NodePattern.new("(array $...)")

    ARG_NAMES_MATCHER = RuboCop::NodePattern.new("(defs _ _ (:args $...) ...)")
    INSTANCE_ARG_MATCHER = RuboCop::NodePattern.new("(def _ (:args $...) ...)")
    PRIVATE_CLASS_ARG_MATCHER = RuboCop::NodePattern.new("(send _ :private_class_method (defs _ _ (:args $...) ...))")

    def self.source(node, args, ret)
      arg_names = arg_names(node)
      arg_types = args.map { |arg| convert(arg) }.flatten
      return_types = convert(ret)
      format_source(arg_types, arg_names, return_types)
    rescue AutoCorrectError => e
      puts e.message
      nil
    end

    def self.format_source(arg_types, arg_names, return_types)
      if arg_names.empty?
        if return_types.nil?
          format("sig { void }", [])
        else
          format("sig { returns(%s) }", return_types)
        end
      else
        params = arg_names.zip(arg_types).map do |arg, arg_type|
          arg_name = CONTRACT_ARGS_PATTERN.match(arg).to_s
          "#{arg_name}: #{arg_type}"
        end.join(", ")
        if return_types.nil?
          return format("sig { params(%s).void }", params)
        else
          return format("sig { params(%s).returns(%s) }", params, return_types)
        end
      end
    end

    def self.arg_names(node)
      sibling = node.parent.children[node.sibling_index + 1]
      arg_names = ARG_NAMES_MATCHER.match(sibling)
      arg_names ||= INSTANCE_ARG_MATCHER.match(sibling)
      arg_names ||= PRIVATE_CLASS_ARG_MATCHER.match(sibling)
      arg_names
    end

    def self.convert(src)
      if CONST_PATTERN.match(src)
        return map_const(CONST_PATTERN.match(src))
      end
      if TWO_CONST_PATTERN.match(src)
        return map_consts(TWO_CONST_PATTERN.match(src))
      end
      if THREE_CONST_PATTERN.match(src)
        return map_consts(THREE_CONST_PATTERN.match(src))
      end
      if FOUR_CONST_PATTERN.match(src)
        return map_consts(FOUR_CONST_PATTERN.match(src))
      end
      if SEND_PATTERN.match(src)
        send, rest = SEND_PATTERN.match(src)
        send_value = map_send(convert(send))
        if send_value == "KeywordArgs"
          # For KeywordArgs we don't want to return the hash as the type;
          # instead, the contents of the hash are the type.
          return hash_entries(rest.first).map { |pair| convert(pair[1]) }
        end
        if send_value && rest
          rest_string = rest.map { |part| convert(part) }.join(", ")
          return format(send_value, rest_string)
        end
      end
      if NIL_PATTERN.match(src)
        return nil
      end
      if SELF_PATTERN.match(src)
        return "T.self_type"
      end
      if CONST_PAIR_MATCHER.match(src)
        first, second = CONST_PAIR_MATCHER.match(src)
        return format("%s, %s", first, second)
      end
      if HASH_PATTERN.match(src)
        hash_vals = hash_entries(src).map { |match| "#{match[0]}: #{convert(match[1])}" }.join(", ")
        return format("{%s}", hash_vals)
      end
      if TUPLE_PATTERN.match(src)
        values = TUPLE_PATTERN.match(src)
        return format("[%s]", values.map { |value| convert(value) }.join(", "))
      end
      # Know we (at least) cannot handle literals
      raise AutoCorrectError, "Could not recognize source #{src}"
    end

    # Given a hash node, return a list of key,value
    def self.hash_entries(hash)
      HASH_PATTERN.match(hash).map { |part| PAIR_MATCHER.match(part) }
    end

    def self.map_consts(consts)
      ret = consts.map(&:to_s).join("::")
      map_const(ret)
    end

    # Map Contract classes to the Sorbet equivalent
    def self.map_const(contracts_value)
      case contracts_value.to_s
      when "Boolean", "Bool", "Contracts::Bool"
        "T::Boolean"
      when "Any", "Contracts::Any"
        "T.untyped"
      when "Hash"
        "T::Hash[T.untyped, T.untyped]"
      when "Proc"
        "T.proc.void"
      when "Num", "Contracts::Num", "Neg", "Contracts::Neg", "Pos", "Contracts::Pos"
        "Numeric"
      when "Int", "Contracts::Int", "Nat", "Contracts::Nat", "NatPos", "Contracts::NatPos"
        "Integer"
      else
        contracts_value.to_s
      end
    end

    # Map Contract functions and generic classes to the Sorbet equivalent
    def self.map_send(contracts_value)
      case contracts_value
      when "Maybe", "Contracts::Maybe"
        "T.nilable(%s)"
      when "ArrayOf", "Contracts::ArrayOf"
        "T::Array[%s]"
      when "HashOf", "Contracts::HashOf"
        "T::Hash[%s]"
      when "Or", "Contracts::Or"
        "T.any(%s)"
      when "KeywordArgs", "Contracts::KeywordArgs"
        # KeywordArgs is handled specifically
        "KeywordArgs"
      when "Optional", "Contracts::Optional"
        "%s"
      when "SetOf"
        "T::Set[%s]"
      when "TryOf"
        "Try[%s]"
      else
        # Know we (at least) cannot handle Enum and KeywordArgs
        raise AutoCorrectError, "Could not recognize send value #{contracts_value}"
      end
    end
  end
end
