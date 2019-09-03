module Sorbet
  class SorbetFromContractService
    class AutoCorrectError < StandardError; end
    CONTRACT_PATTERN = RuboCop::NodePattern.new("$(send _ :Contract $... (:hash (:pair $_ $_)))")

    EXTEND_T_SIG_PATTERN = RuboCop::NodePattern.new("(send _ :extend (const (const _ :T) :Sig))")

    INSTANCE_ARG_MATCHER = RuboCop::NodePattern.new("(def _ (:args $...) ...)")
    ARG_NAMES_MATCHER = RuboCop::NodePattern.new("(defs _ _ (:args $...) ...)")
    PRIVATE_CLASS_ARG_MATCHER = RuboCop::NodePattern.new("(send _ :private_class_method (defs _ _ (:args $...) ...))")
    CONST_PATTERN = RuboCop::NodePattern.new("(const nil? $_)")
    TWO_CONST_PATTERN = RuboCop::NodePattern.new("(const (const nil? $_) $_)")
    THREE_CONST_PATTERN = RuboCop::NodePattern.new("(const (const (const nil? $_) $_) $_)")
    FOUR_CONST_PATTERN = RuboCop::NodePattern.new("(const (const (const (const nil? $_) $_) $_) $_)")
    SEND_PATTERN = RuboCop::NodePattern.new("(send $_ _ $...)")
    NIL_PATTERN = RuboCop::NodePattern.new("nil")
    HASH_PATTERN = RuboCop::NodePattern.new("(hash $...)")
    PAIR_MATCHER = RuboCop::NodePattern.new("(pair ({sym str} $_) $_)")
    CONST_PAIR_MATCHER = RuboCop::NodePattern.new("(hash (pair (const nil? $_) (const nil? $_)))")
    CONTRACT_ARGS_PATTERN = RuboCop::NodePattern.new("({arg optarg blockarg kwoptarg kwarg} $_ ...)")

    ARG_NAMES_MATCHER = RuboCop::NodePattern.new("(defs _ _ (:args $...) ...)")
    INSTANCE_ARG_MATCHER = RuboCop::NodePattern.new("(def _ (:args $...) ...)")
    PRIVATE_CLASS_ARG_MATCHER = RuboCop::NodePattern.new("(send _ :private_class_method (defs _ _ (:args $...) ...))")

    def self.source(node, args, ret)
      arg_names = arg_names(node)
      arg_types = args.map { |arg| convert(arg) }.flatten
      return nil unless arg_types.any? && arg_types.all?
      return_types = convert(ret)
      return format_source(arg_types, arg_names, return_types)
    rescue AutoCorrectError => e
      puts e.message
      return nil
    end

    def self.format_source(arg_types, arg_names, return_types)
      if arg_types.length == 1 && arg_types[0] == "None"
        return format("sig { returns(%s) }", return_types)
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
      if CONST_PAIR_MATCHER.match(src)
        first, second = CONST_PAIR_MATCHER.match(src)
        return format("%s, %s", first, second)
      end
      if HASH_PATTERN.match(src)
        hash_vals = hash_entries(src).map { |match| "#{match[0]}: #{convert(match[1])}" }.join(", ")
        return format("{%s}", hash_vals)
      end
      # Know we (at least) cannot handle literals
      raise AutoCorrectError.new("Could not recognize source #{src}")
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
        return "T::Boolean"
      when "Any", "Contracts::Any"
        return "T.untyped"
      when "Hash"
        return "T::Hash"
      when "Proc"
        return "T.proc.void"
      when "Contracts::Num"
        return "Numeric"
      when "Int", "Contracts::Int"
        return "Integer"
      else
        contracts_value.to_s
      end
    end

    # Map Contract functions and generic classes to the Sorbet equivalent
    def self.map_send(contracts_value)
      case contracts_value
      when "Maybe", "Contracts::Maybe"
        return "T.nilable(%s)"
      when "ArrayOf", "Contracts::ArrayOf"
        return "T::Array[%s]"
      when "HashOf", "Contracts::HashOf"
        return "T::Hash[%s]"
      when "Or", "Contracts::Or"
        return "T.any(%s)"
      when "KeywordArgs"
        # KeywordArgs is handled specifically
        return "KeywordArgs"
      when "Optional"
        return "%s"
      when "SetOf"
        return "T::Set[%s]"
      when "TryOf"
        return "Try[%s]"
      else
        # Know we (at least) cannot handle Enum and KeywordArgs
        raise AutoCorrectError.new("Could not recognize send value #{contracts_value}")
      end
    end
  end
end
# rubocop:enable Style/FormatStringToken, Performance/RegexpMatch
