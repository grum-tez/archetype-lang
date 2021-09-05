open Parser
open Parser.MenhirInterpreter

let string_of_token = function
  | XOR                  -> "XOR"
  | WITH                 -> "WITH"
  | WITH_METADATA        -> "WITH_METADATA"
  | WHILE                -> "WHILE"
  | WHEN                 -> "WHEN"
  | VIEW                 -> "VIEW"
  | VARIABLE             -> "VARIABLE"
  | VAR                  -> "VAR"
  | UTZ n                -> Printf.sprintf "UTZ(%s)" n
  | USE                  -> "USE"
  | UNPACK               -> "UNPACK"
  | UNMOVED              -> "UNMOVED"
  | UNIT                 -> "UNIT"
  | UNDERSCORE           -> "UNDERSCORE"
  | TZ n                 -> Printf.sprintf "TZ(%s)" n
  | TYPE                 -> "TYPE"
  | TRUE                 -> "TRUE"
  | TRANSITION           -> "TRANSITION"
  | TRANSFER             -> "TRANSFER"
  | TO                   -> "TO"
  | TICKET               -> "TICKET"
  | THEN                 -> "THEN"
  | STRING s             -> Printf.sprintf "STRING(%s)" s
  | STRING_EXT s         -> Printf.sprintf "STRING_EXT(%s)" s
  | STATES               -> "STATES"
  | STATE_IS             -> "STATE_IS"
  | SPECIFICATION        -> "SPECIFICATION"
  | SOURCED              -> "SOURCED"
  | SORTED               -> "SORTED"
  | SOME                 -> "SOME"
  | SLASHPERCENT         -> "SLASHPERCENT"
  | SLASH                -> "SLASH"
  | SHADOW               -> "SHADOW"
  | SET                  -> "SET"
  | SEMI_COLON           -> "SEMI_COLON"
  | SELF                 -> "SELF"
  | SECURITY             -> "SECURITY"
  | SAPLING_TRANSACTION  -> "SAPLING_TRANSACTION"
  | SAPLING_STATE        -> "SAPLING_STATE"
  | RPAREN               -> "RPAREN"
  | RIGHT                -> "RIGHT"
  | RETURN               -> "RETURN"
  | REQUIRE_ENTRYPOINT   -> "REQUIRE_ENTRYPOINT"
  | REQUIRE              -> "REQUIRE"
  | REMOVED              -> "REMOVED"
  | REFUSE_TRANSFER      -> "REFUSE_TRANSFER"
  | REF                  -> "REF"
  | RECORD               -> "RECORD"
  | RBRACKET             -> "RBRACKET"
  | RBRACE               -> "RBRACE"
  | PREDICATE            -> "PREDICATE"
  | POSTCONDITION        -> "POSTCONDITION"
  | PLUSEQUAL            -> "PLUSEQUAL"
  | PLUS                 -> "PLUS"
  | PKEY                 -> "PKEY"
  | PIPEEQUAL            -> "OREQUAL"
  | PIPE_GREATER_GREATER -> "PIPE_GREATER_GREATER"
  | PIPE                 -> "PIPE"
  | PIDENT s             -> Printf.sprintf "PIDENT(%s)" s
  | PERCENTRBRACKET      -> "PERCENTRBRACKET"
  | PERCENT_LIT n        -> Printf.sprintf "PERCENT_LIT(%s)" n
  | PERCENT              -> "PERCENT"
  | PARTITION            -> "PARTITION"
  | OTHERWISE            -> "OTHERWISE"
  | OR                   -> "OR"
  | OPTION               -> "OPTION"
  | ON                   -> "ON"
  | NUMBERNAT n          -> Printf.sprintf "NUMBERNAT(%s)" (Big_int.string_of_big_int n)
  | NUMBERINT n          -> Printf.sprintf "NUMBERINT(%s)" (Big_int.string_of_big_int n)
  | NOT                  -> "NOT"
  | NONE                 -> "NONE"
  | NEQUAL               -> "NEQUAL"
  | NAMESPACE            -> "NAMESPACE"
  | MULTEQUAL            -> "MULTEQUAL"
  | MULT                 -> "MULT"
  | MTZ n                -> Printf.sprintf "MTZ(%s)" n
  | MINUSEQUAL           -> "MINUSEQUAL"
  | MINUS                -> "MINUS"
  | MATCH                -> "MATCH"
  | MAP                  -> "MAP"
  | LPAREN               -> "LPAREN"
  | LIST                 -> "LIST"
  | LET                  -> "LET"
  | LESSEQUAL            -> "LESSEQUAL"
  | LESS_LESS_PIPE       -> "LESS_LESS_PIPE"
  | LESS_EQUAL_GREATER   -> "LESS_EQUAL_GREATER"
  | LESS                 -> "LESS"
  | LEFT                 -> "LEFT"
  | LBRACKETPERCENT      -> "LBRACKETPERCENT"
  | LBRACKET             -> "LBRACKET"
  | LBRACE               -> "LBRACE"
  | LAMBDA               -> "LAMBDA"
  | LABEL                -> "LABEL"
  | ITER                 -> "ITER"
  | INVARIANT            -> "INVARIANT"
  | INVALID_EXPR         -> "INVALID_EXPR"
  | INVALID_EFFECT       -> "INVALID_EFFECT"
  | INVALID_DECL         -> "INVALID_DECL"
  | INITIALIZED          -> "INITIALIZED"
  | INITIAL              -> "INITIAL"
  | IN                   -> "IN"
  | IMPLY                -> "IMPLY"
  | IF                   -> "IF"
  | IDENTIFIED           -> "IDENTIFIED"
  | IDENT s              -> Printf.sprintf "IDENT(%s)" s
  | GREATEREQUAL         -> "GREATEREQUAL"
  | GREATER              -> "GREATER"
  | GETTER               -> "GETTER"
  | FUNCTION             -> "FUNCTION"
  | FROM                 -> "FROM"
  | FORALL               -> "FORALL"
  | FOR                  -> "FOR"
  | FOLD                 -> "FOLD"
  | FALSE                -> "FALSE"
  | FAILS                -> "FAILS"
  | FAILIF               -> "FAILIF"
  | FAIL                 -> "FAIL"
  | EXTENSION            -> "EXTENSION"
  | EXISTS               -> "EXISTS"
  | EQUIV                -> "EQUIV"
  | EQUAL                -> "EQUAL"
  | EOF                  -> "EOF"
  | ENUM                 -> "ENUM"
  | ENTRYPOINT           -> "ENTRYPOINT"
  | ENTRY                -> "ENTRY"
  | END                  -> "END"
  | ELSE                 -> "ELSE"
  | EFFECT               -> "EFFECT"
  | DURATION s           -> Printf.sprintf "DURATION(%s)" s
  | DOT                  -> "DOT"
  | DOREQUIRE            -> "DOREQUIRE"
  | DONE                 -> "DONE"
  | DOFAILIF             -> "DOFAILIF"
  | DO                   -> "DO"
  | DIVEQUAL             -> "DIVEQUAL"
  | DIV                  -> "DIV"
  | DEFINITION           -> "DEFINITION"
  | DECIMAL s            -> Printf.sprintf "DECIMAL(%s)" s
  | DATE s               -> Printf.sprintf "DATE(%s)" s
  | CONTRACT             -> "CONTRACT"
  | CONSTANT             -> "CONSTANT"
  | CONST                -> "CONST"
  | COMMA                -> "COMMA"
  | COLONEQUAL           -> "COLONEQUAL"
  | COLONCOLON           -> "COLONCOLON"
  | COLON                -> "COLON"
  | CALLED               -> "CALLED"
  | CALL                 -> "CALL"
  | BYTES s              -> Printf.sprintf "BYTES(%s)" s
  | BY                   -> "BY"
  | BUT                  -> "BUT"
  | BIG_MAP              -> "BIG_MAP"
  | BEGIN                -> "BEGIN"
  | BEFORE               -> "BEFORE"
  | AT_UPDATE            -> "AT_UPDATE"
  | AT_REMOVE            -> "AT_REMOVE"
  | AT_ADD               -> "AT_ADD"
  | AT                   -> "AT"
  | ASSET                -> "ASSET"
  | ASSERT               -> "ASSERT"
  | AS                   -> "AS"
  | ARCHETYPE            -> "ARCHETYPE"
  | ANY                  -> "ANY"
  | AND                  -> "AND"
  | AMPEQUAL             -> "AMPEQUAL"
  | AGGREGATE            -> "AGGREGATE"
  | ADDRESS s            -> Printf.sprintf "DURATION(%s)" s
  | ADDED                -> "ADDED"
  | ACCEPT_TRANSFER      -> "ACCEPT_TRANSFER"

let string_of_symbol = function
  | X (T T_XOR) -> "xor"
  | X (T T_WITH) -> "with"
  | X (T T_WITH_METADATA) -> "with metadata"
  | X (T T_WHILE) -> "while"
  | X (T T_WHEN) -> "when"
  | X (T T_VIEW) -> "view"
  | X (T T_VARIABLE) -> "variable"
  | X (T T_VAR) -> "var"
  | X (T T_UTZ) -> "a utz"
  | X (T T_USE) -> "use"
  | X (T T_UNPACK) -> "unpack"
  | X (T T_UNMOVED) -> "unmoved"
  | X (T T_UNIT) -> "Unit"
  | X (T T_UNDERSCORE) -> "_"
  | X (T T_TZ) -> "a tz"
  | X (T T_TYPE) -> "a type"
  | X (T T_TRUE) -> "true"
  | X (T T_TRANSITION) -> "transition"
  | X (T T_TRANSFER) -> "transfer"
  | X (T T_TO) -> "to"
  | X (T T_TICKET) -> "ticket"
  | X (T T_THEN) -> "then"
  | X (T T_STRING) -> "a string"
  | X (T T_STRING_EXT) -> "a string ext"
  | X (T T_STATES) -> "states"
  | X (T T_STATE_IS) -> "state is"
  | X (T T_SPECIFICATION) -> "postcondition"
  | X (T T_SOURCED) -> "sourced"
  | X (T T_SORTED) -> "sorted"
  | X (T T_SOME) -> "some"
  | X (T T_SLASHPERCENT) -> "slashpercent"
  | X (T T_SLASH) -> "slash"
  | X (T T_SHADOW) -> "shadow"
  | X (T T_SET) -> "set"
  | X (T T_SEMI_COLON) -> ";"
  | X (T T_SELF) -> "self"
  | X (T T_SECURITY) -> "security"
  | X (T T_SAPLING_TRANSACTION) -> "sapling_transaction"
  | X (T T_SAPLING_STATE) -> "sapling_state"
  | X (T T_RPAREN) -> ")"
  | X (T T_RIGHT) -> "right"
  | X (T T_RETURN) -> "return"
  | X (T T_REQUIRE_ENTRYPOINT) -> "require_entrypoint"
  | X (T T_REQUIRE) -> "require"
  | X (T T_REMOVED) -> "removed"
  | X (T T_REFUSE_TRANSFER) -> "refuse transfer"
  | X (T T_REF) -> "ref"
  | X (T T_RECORD) -> "record"
  | X (T T_RBRACKET) -> "]"
  | X (T T_RBRACE) -> "}"
  | X (T T_PREDICATE) -> "predicate"
  | X (T T_POSTCONDITION) -> "postcondition"
  | X (T T_PLUSEQUAL) -> "+="
  | X (T T_PLUS) -> "+"
  | X (T T_PKEY) -> "pkey"
  | X (T T_PIPEEQUAL) -> "|="
  | X (T T_PIPE) -> "|"
  | X (T T_PIPE_GREATER_GREATER) -> "|>>"
  | X (T T_PIDENT) -> "an pident"
  | X (T T_PERCENTRBRACKET) -> "%]"
  | X (T T_PERCENT) -> "%"
  | X (T T_PERCENT_LIT) -> "a literal percent"
  | X (T T_PARTITION) -> "partition"
  | X (T T_OTHERWISE) -> "otherwise"
  | X (T T_OR) -> "or"
  | X (T T_OPTION) -> "option"
  | X (T T_ON) -> "on"
  | X (T T_NUMBERNAT) -> "a nat number"
  | X (T T_NUMBERINT) -> "a int number"
  | X (T T_NOT) -> "not"
  | X (T T_NONE) -> "none"
  | X (T T_NEQUAL) -> "<>"
  | X (T T_NAMESPACE) -> "namespace"
  | X (T T_MULTEQUAL) -> "*="
  | X (T T_MULT) -> "*"
  | X (T T_MTZ) -> "a mtz"
  | X (T T_MINUSEQUAL) -> "-="
  | X (T T_MINUS) -> "-"
  | X (T T_MATCH) -> "match"
  | X (T T_MAP) -> "map"
  | X (T T_LPAREN) -> "("
  | X (T T_LIST) -> "list"
  | X (T T_LET) -> "let"
  | X (T T_LESSEQUAL) -> "<="
  | X (T T_LESS) -> "<"
  | X (T T_LESS_LESS_PIPE) -> "<<|"
  | X (T T_LESS_EQUAL_GREATER) -> "<=>"
  | X (T T_LEFT) -> "left"
  | X (T T_LBRACKETPERCENT) -> "[%"
  | X (T T_LBRACKET) -> "["
  | X (T T_LBRACE) -> "{"
  | X (T T_LAMBDA) -> "lambda"
  | X (T T_LABEL) -> "label"
  | X (T T_ITER) -> "iter"
  | X (T T_INVARIANT) -> "invariant"
  | X (T T_INVALID_EXPR) -> "invalid-expression"
  | X (T T_INVALID_EFFECT) -> "invalid-effect"
  | X (T T_INVALID_DECL) -> "invalid-declaration"
  | X (T T_INITIALIZED) -> "initialized"
  | X (T T_INITIAL) -> "initial"
  | X (T T_IN) -> "in"
  | X (T T_IMPLY) -> "->"
  | X (T T_IF) -> "if"
  | X (T T_IDENTIFIED) -> "identified"
  | X (T T_IDENT) -> "an ident"
  | X (T T_GREATEREQUAL) -> ">="
  | X (T T_GREATER) -> ">"
  | X (T T_GETTER) -> "getter"
  | X (T T_FUNCTION) -> "function"
  | X (T T_FROM) -> "from"
  | X (T T_FORALL) -> "forall"
  | X (T T_FOR) -> "for"
  | X (T T_FOLD) -> "fold"
  | X (T T_FALSE) -> "false"
  | X (T T_FAILS) -> "fails"
  | X (T T_FAILIF) -> "failif"
  | X (T T_FAIL) -> "fail"
  | X (T T_EXTENSION) -> "extension"
  | X (T T_EXISTS) -> "exists"
  | X (T T_error) -> "error"
  | X (T T_EQUIV) -> "<->"
  | X (T T_EQUAL) -> "="
  | X (T T_EOF) -> "end-of-file"
  | X (T T_ENUM) -> "enum"
  | X (T T_ENTRYPOINT) -> "entrypoint"
  | X (T T_ENTRY) -> "entry"
  | X (T T_END) -> "end"
  | X (T T_ELSE) -> "else"
  | X (T T_EFFECT) -> "effect"
  | X (T T_DURATION) -> "duration"
  | X (T T_DOT) -> "."
  | X (T T_DOREQUIRE) -> "dorequire"
  | X (T T_DONE) -> "done"
  | X (T T_DOFAILIF) -> "dofailif"
  | X (T T_DO) -> "do"
  | X (T T_DIVEQUAL) -> "/="
  | X (T T_DIV) -> "/"
  | X (T T_DEFINITION) -> "definition"
  | X (T T_DECIMAL) -> "decimal"
  | X (T T_DATE) -> "a date"
  | X (T T_CONTRACT) -> "contract"
  | X (T T_CONSTANT) -> "constant"
  | X (T T_CONST) -> "const"
  | X (T T_COMMA) -> ","
  | X (T T_COLONEQUAL) -> ":="
  | X (T T_COLONCOLON) -> "::"
  | X (T T_COLON) -> ":"
  | X (T T_CALLED) -> "called"
  | X (T T_CALL) -> "call"
  | X (T T_BYTES) -> "bytes"
  | X (T T_BY) -> "by"
  | X (T T_BUT) -> "but"
  | X (T T_BIG_MAP) -> "big_map"
  | X (T T_BEGIN) -> "begin"
  | X (T T_BEFORE) -> "before"
  | X (T T_AT) -> "at"
  | X (T T_AT_UPDATE) -> "@update"
  | X (T T_AT_REMOVE) -> "@remove"
  | X (T T_AT_ADD) -> "@add"
  | X (T T_ASSET) -> "asset"
  | X (T T_ASSERT) -> "assert"
  | X (T T_AS) -> "as"
  | X (T T_ARCHETYPE) -> "archetype"
  | X (T T_ANY) -> "any"
  | X (T T_AND) -> "and"
  | X (T T_AMPEQUAL) -> "%="
  | X (T T_AGGREGATE) -> "aggregate"
  | X (T T_ADDRESS) -> "an address"
  | X (T T_ADDED) -> "added"
  | X (T T_ACCEPT_TRANSFER) -> "accept address"
  | X (N N_vc_decl_VARIABLE_) -> "a variable declaration"
  | X (N N_vc_decl_CONSTANT_) -> "a constant declaration"
  | X (N N_variable) -> "a variable"
  | X (N N_type_s_unloc) -> "types"
  | X (N N_type_r) -> "a type"
  | X (N N_type_decl) -> "a type decl"
  | X (N N_transition) -> "a transition"
  | X (N N_transition_to_item) -> "a transition to item"
  | X (N N_start_expr) -> "a start expression"
  | X (N N_specvariable) -> "a specvariable"
  | X (N N_specification_fun) -> "a specification function"
  | X (N N_specification_decl) -> "a specification declaration"
  | X (N N_specgetter) -> "a specgetter"
  | X (N N_specfun) -> "a specfun"
  | X (N N_specfun_gen_GETTER_) -> "a spec GETTER"
  | X (N N_specfun_gen_FUNCTION_) -> "a spec FUNCTION"
  | X (N N_specfun_gen_ENTRY_) -> "a spec ENTRY"
  | X (N N_specentry) -> "a specentry"
  | X (N N_specasset) -> "a specasset"
  | X (N N_spec_items) -> "a list of specification item"
  | X (N N_sourcedby) -> "a sourced by"
  | X (N N_snl2_OR_security_arg_) -> "a non empty list of security argument separated by  OR"
  | X (N N_snl2_COMMA_expr_) -> "a non empty list of expression separated by  ,"
  | X (N N_snl_SEMI_COLON_security_item_) -> "a non empty list of security item"
  | X (N N_snl_SEMI_COLON_rf_WITH__) -> "a list of rf with"
  | X (N N_snl_SEMI_COLON_rf_OTHERWISE__) -> "a list of rf otherwise"
  | X (N N_snl_SEMI_COLON_label_expr_) -> "a non empty list of label expr"
  | X (N N_snl_SEMI_COLON_field_) -> "a non empty list of field"
  | X (N N_snl_COMMA_simple_expr_) -> ""
  | X (N N_snl_COMMA_security_arg_) -> "a non empty list of security argument"
  | X (N N_snl_COMMA_parameter_) -> "a non empty list of parameter"
  | X (N N_snl_COMMA_function_arg_) -> "a non empty list of function argument"
  | X (N N_snl_COMMA_expr_) -> ""
  | X (N N_sl_SEMI_COLON_security_item_) -> "a list of security item"
  | X (N N_sl_SEMI_COLON_field_) -> "a list of field"
  | X (N N_sl_COMMA_simple_expr_) -> ""
  | X (N N_sl_COMMA_security_arg_) -> "a list of security argument"
  | X (N N_sl_COMMA_function_arg_) -> "a list of function argument"
  | X (N N_simple_expr_r) -> "a simple expression"
  | X (N N_separated_nonempty_list_SEMI_COLON_recupdate_item_) -> "a non empty list of record update item by ;"
  | X (N N_separated_nonempty_list_SEMI_COLON_record_item_) -> "a non empty list of record item by ;"
  | X (N N_separated_nonempty_list_SEMI_COLON_record_expr_) -> "a non empty list of record expression by ;"
  | X (N N_separated_nonempty_list_MULT_type_s_) -> "a non empty *-separated list of types"
  | X (N N_separated_nonempty_list_COMMA_security_arg_) -> "a non empty list of security arg"
  | X (N N_separated_nonempty_list_COMMA_ident_) -> "a non empty comma-separated list of identifiers"
  | X (N N_security_decl) -> "a security declaration"
  | X (N N_security_decl_unloc) -> "a security declaration"
  | X (N N_security_arg_unloc) -> "a security argument"
  | X (N N_rf_WITH_) -> "rf with"
  | X (N N_rf_OTHERWISE_) -> "rf otherwise"
  | X (N N_recupdate_item) -> "a record update item"
  | X (N N_record) -> "a record"
  | X (N N_record_item) -> "a record item"
  | X (N N_pname) -> "a pattern identifier"
  | X (N N_order_operations) -> "order operations"
  | X (N N_order_operation) -> "an order operation"
  | X (N N_option_with_effect_) -> "a with effect option"
  | X (N N_option_state_is_) -> "an option state is"
  | X (N N_option_specification_fun_) -> "a specification function option"
  | X (N N_option_sourcedby_) -> "an option sourced by"
  | X (N N_option_simple_expr_) -> "a simple expression option"
  | X (N N_option_SEMI_COLON_) -> ""
  | X (N N_option_require_value_) -> "a require option"
  | X (N N_option_require_) -> "a require option"
  | X (N N_option_record_position_) -> "an option record position"
  | X (N N_option_prefix_EQUAL_enum_body__) -> "an optional enum body"
  | X (N N_option_paren_separated_nonempty_list_COMMA_ident___) -> "a list of constructor arguments"
  | X (N N_option_parameter_init_) -> "parameter initialization"
  | X (N N_option_on_value_) -> "a on value option"
  | X (N N_option_ident_) -> "an option ident"
  | X (N N_option_function_return_) -> "a function return option"
  | X (N N_option_failif_) -> "a failif option"
  | X (N N_option_extensions_) -> "extensions option"
  | X (N N_option_effect_) -> "an effect option"
  | X (N N_option_default_value_) -> "a default value option"
  | X (N N_option_calledby_) -> "a call by option"
  | X (N N_option_bracket_asset_operation__) -> "a list of asset operation"
  | X (N N_option_asset_options_) -> "assets option"
  | X (N N_option_asset_fields_) -> "asset fields option"
  | X (N N_on_value) -> "on value"
  | X (N N_nonempty_list_type_tuple_) -> "a non empty list of type tuple"
  | X (N N_nonempty_list_transition_to_item_) -> "a non empty list of transition to item"
  | X (N N_nonempty_list_spec_fail_item_) -> "a list of spec fail item"
  | X (N N_nonempty_list_loc_pattern__) -> "a non empty list of pattern"
  | X (N N_nonempty_list_ident_typ_q_item_) -> "a non empty list of typed identifier"
  | X (N N_nonempty_list_ident_) -> "a non empty list of identifier"
  | X (N N_nonempty_list_extension_) -> "a non empty list of extension"
  | X (N N_nonempty_list_declaration_) -> "a non empty list of declaration"
  | X (N N_nonempty_list_branch_) -> "a non empty list of branch"
  | X (N N_nonempty_list_asset_option_) -> "a non empty list of asset option"
  | X (N N_nonempty_list_asset_operation_enum_) -> "a non empty list of asset operation enum"
  | X (N N_namespace) -> "a namespace"
  | X (N N_main) -> "archetype"
  | X (N N_loption_separated_nonempty_list_SEMI_COLON_recupdate_item__) -> "a non empty list of record update item"
  | X (N N_loption_separated_nonempty_list_SEMI_COLON_record_item__) -> "a non empty list of record item"
  | X (N N_loption_separated_nonempty_list_COMMA_security_arg__) -> "a non empty list of security arg"
  | X (N N_literal) -> "a literal"
  | X (N N_list_loc_spec_variable__) -> "a list of specification variable item"
  | X (N N_list_loc_spec_predicate__ ) -> "a list of specification predicate item"
  | X (N N_list_loc_spec_postcondition__) -> "a list of specification postcondition item"
  | X (N N_list_loc_spec_fails__) -> "a list of loc spec fails"
  | X (N N_list_loc_spec_effect__) -> "a list of specification effect item"
  | X (N N_list_loc_spec_definition__) -> "a list of specification definition item"
  | X (N N_list_loc_spec_contract_invariant__) -> "a list of specification contract invariant item"
  | X (N N_list_loc_spec_assert__) -> "a list of specification assert item"
  | X (N N_list_invars_) -> "a list of invariants"
  | X (N N_list_function_item_) -> "a list of item function"
  | X (N N_list_enum_option_) -> "an optional list of enum options"
  | X (N N_list_enum_cdecl_) -> "a list of enum constructors declarations"
  | X (N N_list_asset_post_option_) -> "a list of asset post option"
  | X (N N_label_expr_unloc) -> "a label expr"
  | X (N N_implementation_archetype) -> "an archetype implementation"
  | X (N N_ident_typ_q) -> "an item of type"
  | X (N N_getter_decl) -> "a getter declaration"
  | X (N N_function_item) -> "an item function"
  | X (N N_function_decl) -> "a function declaration"
  | X (N N_field_r) -> "a field"
  | X (N N_extension_r) -> "an extension"
  | X (N N_expr_r) -> "an expression"
  | X (N N_enum) -> "an enum"
  | X (N N_enum_option) -> "an enum option"
  | X (N N_enum_cdecl) -> "an enum constructor declaration"
  | X (N N_enum_body) -> "an enum body declaration"
  | X (N N_entry) -> "an entry"
  | X (N N_entry_simple) -> "an entry simple"
  | X (N N_entry_properties) -> "entry properties"
  | X (N N_effect) -> "an effect"
  | X (N N_dextension) -> "a extension declaration"
  | X (N N_declaration_r) -> "a declaration"
  | X (N N_constant) -> "a constant"
  | X (N N_calledby) -> "called by"
  | X (N N_branch) -> "branch"
  | X (N N_boption_REF_) -> "ref option"
  | X (N N_boption_CONST_) -> "an optional const"
  | X (N N_asset) -> "an asset"
  | X (N N_asset_post_option) -> "asset post option"
  | X (N N_asset_option) -> "an asset option"
  | X (N N_archetype) -> "archetype"
  | X (N N_archetype_r) -> "archetype"
  | X (N N_archetype_extension) -> "an extension"

let string_of_item (p, i) =
  string_of_symbol (lhs p) ^ " -> "
  ^ String.concat " " (
    List.mapi (fun j s ->
        (if j = i then "." else "") ^ string_of_symbol s)
      (rhs p))
  ^ (if i = List.length (rhs p) then "." else "")
