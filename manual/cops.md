## Available cops

In the following section you find all available cops:

<!-- START_COP_LIST -->
#### Department [Sorbet](cops_sorbet.md)

* [Sorbet/AllowIncompatibleOverride](cops_sorbet.md#sorbetallowincompatibleoverride)
* [Sorbet/BindingConstantWithoutTypeAlias](cops_sorbet.md#sorbetbindingconstantwithouttypealias)
* [Sorbet/CallbackConditionalsBinding](cops_sorbet.md#sorbetcallbackconditionalsbinding)
* [Sorbet/CheckedTrueInSignature](cops_sorbet.md#sorbetcheckedtrueinsignature)
* [Sorbet/ConstantsFromStrings](cops_sorbet.md#sorbetconstantsfromstrings)
* [Sorbet/EmptyLineAfterSig](cops_sorbet.md#sorbetemptylineaftersig)
* [Sorbet/EnforceSigilOrder](cops_sorbet.md#sorbetenforcesigilorder)
* [Sorbet/EnforceSignatures](cops_sorbet.md#sorbetenforcesignatures)
* [Sorbet/EnforceSingleSigil](cops_sorbet.md#sorbetenforcesinglesigil)
* [Sorbet/FalseSigil](cops_sorbet.md#sorbetfalsesigil)
* [Sorbet/ForbidExtendTSigHelpersInShims](cops_sorbet.md#sorbetforbidextendtsighelpersinshims)
* [Sorbet/ForbidIncludeConstLiteral](cops_sorbet.md#sorbetforbidincludeconstliteral)
* [Sorbet/ForbidRBIOutsideOfAllowedPaths](cops_sorbet.md#sorbetforbidrbioutsideofallowedpaths)
* [Sorbet/ForbidSuperclassConstLiteral](cops_sorbet.md#sorbetforbidsuperclassconstliteral)
* [Sorbet/ForbidTUnsafe](cops_sorbet.md#sorbetforbidtunsafe)
* [Sorbet/ForbidTUntyped](cops_sorbet.md#sorbetforbidtuntyped)
* [Sorbet/ForbidUntypedStructProps](cops_sorbet.md#sorbetforbiduntypedstructprops)
* [Sorbet/HasSigil](cops_sorbet.md#sorbethassigil)
* [Sorbet/IgnoreSigil](cops_sorbet.md#sorbetignoresigil)
* [Sorbet/KeywordArgumentOrdering](cops_sorbet.md#sorbetkeywordargumentordering)
* [Sorbet/OneAncestorPerLine](cops_sorbet.md#sorbetoneancestorperline)
* [Sorbet/RedundantExtendTSig](cops_sorbet.md#sorbetredundantextendtsig)
* [Sorbet/SignatureBuildOrder](cops_sorbet.md#sorbetsignaturebuildorder)
* [Sorbet/SignatureCop](cops_sorbet.md#sorbetsignaturecop)
* [Sorbet/SingleLineRbiClassModuleDefinitions](cops_sorbet.md#sorbetsinglelinerbiclassmoduledefinitions)
* [Sorbet/StrictSigil](cops_sorbet.md#sorbetstrictsigil)
* [Sorbet/StrongSigil](cops_sorbet.md#sorbetstrongsigil)
* [Sorbet/TrueSigil](cops_sorbet.md#sorbettruesigil)
* [Sorbet/TypeAliasName](cops_sorbet.md#sorbettypealiasname)
* [Sorbet/ValidSigil](cops_sorbet.md#sorbetvalidsigil)

<!-- END_COP_LIST -->

In addition to the cops defined in this gem, it also modifies the behaviour of some other cops
defined in other RuboCop gems:

* [Style/MutableConstant](https://docs.rubocop.org/rubocop/cops_style.html#stylemutableconstant): In addition to the default behaviour, RuboCop Sorbet makes this cop `T.let` aware, so that `CONST = T.let([1, 2, 3], T::Array[Integer])` is also treated as a mutable literal constant value.
