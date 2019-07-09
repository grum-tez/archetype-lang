open Location
open Tools

module A = Ast
module M = Model

exception Anomaly of string
type error_desc =
  | NotSupportedContainer of string
  | UnsupportedTypeForFile of A.type_
  | CannotConvertToAssignOperator
  | CannotSetApiItem
  | TODO
[@@deriving show {with_path = false}]

let emit_error (desc : error_desc) =
  let str = Format.asprintf "%a@." pp_error_desc desc in
  raise (Anomaly str)

let to_model (ast : A.model) : M.model =


  let to_container c =
    match c with
    | A.Collection -> M.Collection
    | A.Partition  -> M.Partition
    | _            -> emit_error (NotSupportedContainer (Format.asprintf "%a@." A.pp_container c))
  in

  let to_currency = function
    | A.Tez   -> M.Tez
    | A.Mutez -> M.Mutez
  in

  let vtyp_to_btyp = function
    | A.VTbool       -> M.Bbool
    | A.VTint        -> M.Bint
    | A.VTuint       -> M.Buint
    | A.VTrational   -> M.Brational
    | A.VTdate       -> M.Bdate
    | A.VTduration   -> M.Bduration
    | A.VTstring     -> M.Bstring
    | A.VTaddress    -> M.Baddress
    | A.VTrole       -> M.Brole
    | A.VTcurrency c -> M.Bcurrency (to_currency c)
    | A.VTkey        -> M.Bkey
  in

  let rec ptyp_to_type (t : A.ptyp) : M.type_ =
    match t with
    | A.Tasset id          -> M.Tasset id
    | A.Tenum id           -> M.Tenum id
    | A.Tcontract id       -> M.Tcontract id
    | A.Tbuiltin b         -> M.Tbuiltin (vtyp_to_btyp b)
    | A.Tcontainer (t, c)  -> M.Tcontainer (ptyp_to_type t, to_container c)
    | A.Ttuple l           -> M.Ttuple (List.map ptyp_to_type l)
    | A.Tentry             -> M.Tentry
    | A.Toption t          -> M.Toption (ptyp_to_type t)
  in

  let to_trtyp = function
    | A.TRentry  -> M.TRentry
    | A.TRaction -> M.TRaction
    | A.TRasset  -> M.TRasset
    | A.TRfield  -> M.TRfield
  in

  let rec ltyp_to_type t : M.type_ =
    match t with
    | A.LTprog t      -> ptyp_to_type t
    | A.LTvset (v, t) -> ltyp_to_type t
    | A.LTtrace tr    -> M.Ttrace (to_trtyp tr)
  in

  let to_assignment_operator = function
    | A.ValueAssign  -> M.ValueAssign
    | A.PlusAssign   -> M.PlusAssign
    | A.MinusAssign  -> M.MinusAssign
    | A.MultAssign   -> M.MultAssign
    | A.DivAssign    -> M.DivAssign
    | A.AndAssign    -> M.AndAssign
    | A.OrAssign     -> M.OrAssign
  in

  let to_assign_operator = function
    | `Assign op -> to_assignment_operator op
    | _ -> emit_error CannotConvertToAssignOperator
  in

  let rec to_qualid_node (n : ('a, 'b) A.qualid_node) : ('id, 'qualid) M.qualid_node =
    match n with
    | A.Qident i    -> M.Qident i
    | A.Qdot (d, i) -> M.Qdot (to_qualid_gen d, i)

  and to_qualid_gen (q : A.qualid) : M.qualid =
    let node = to_qualid_node q.node in
    let type_ = ptyp_to_type (Option.get q.type_) in
    M.mk_qualid node type_
  in

  let to_pattern_node (n : (A.lident, A.lident A.pattern_gen) A.pattern_node) : 'id M.pattern_node =
    match n with
    | A.Mconst id -> M.Pconst id
    | A.Mwild    -> M.Pwild
  in

  let to_pattern (p : A.pattern) : M.pattern =
    let node = to_pattern_node p.node in
    M.mk_pattern node ~loc:p.loc
  in

  let term_arg_to_expr : 't. ((A.lident, 't) A.term_gen -> M.mterm) -> ((A.lident, 't, (A.lident, 't) A.term_gen) A.term_arg) -> M.mterm =
    fun f a ->
      match a with
      | A.AExpr x -> f x
      | _ -> assert false
      (*| A.AEffect l -> M.AEffect (List.map (fun (id, op, term) -> (id, to_assignment_operator2 op, f term)) l)
        | A.AFun _ -> assert false (* TODO *)*)
  in

  let to_mterm_node : 't. ((A.lident, 't, (A.lident, 't) A.term_gen) A.term_node) -> ((A.lident, 't) A.term_gen -> M.mterm) -> ('t -> M.type_) -> (M.lident, M.mterm) M.mterm_node =
    fun n f ftyp ->
      match n with
      | A.Pif (c, t, e)                -> M.Mif        (f c, f t, f e)
      | A.Pmatchwith (m, l)            -> M.Mmatchwith (f m, List.map (fun (p, e) -> (to_pattern p, f e)) l)
      | A.Plogical (A.And, l, r)       -> M.Mand       (f l, f r)
      | A.Plogical (A.Or, l, r)        -> M.Mor        (f l, f r)
      | A.Plogical (A.Imply, l, r)     -> M.Mimply     (f l, f r)
      | A.Plogical (A.Equiv, l, r)     -> M.Mequiv     (f l, f r)
      | A.Pnot e                       -> M.Mnot       (f e)
      | A.Pcomp (A.Equal, l, r)        -> M.Mequal     (f l, f r)
      | A.Pcomp (A.Nequal, l, r)       -> M.Mnequal    (f l, f r)
      | A.Pcomp (A.Gt, l, r)           -> M.Mgt        (f l, f r)
      | A.Pcomp (A.Ge, l, r)           -> M.Mge        (f l, f r)
      | A.Pcomp (A.Lt, l, r)           -> M.Mlt        (f l, f r)
      | A.Pcomp (A.Le, l, r)           -> M.Mle        (f l, f r)
      | A.Parith (A.Plus, l, r)        -> M.Mplus      (f l, f r)
      | A.Parith (A.Minus, l, r)       -> M.Mminus     (f l, f r)
      | A.Parith (A.Mult, l, r)        -> M.Mmult      (f l, f r)
      | A.Parith (A.Div, l, r)         -> M.Mdiv       (f l, f r)
      | A.Parith (A.Modulo, l, r)      -> M.Mmodulo    (f l, f r)
      | A.Puarith (A.Uplus, e)         -> M.Muplus     (f e)
      | A.Puarith (A.Uminus, e)        -> M.Muminus    (f e)
      | A.Precord l                    -> M.Mrecord    (List.map f l)
      | A.Pletin (id, init, typ, cont) -> M.Mletin     (id, f init, Option.map ftyp typ, f cont)
      | A.Pvar id when A.Utils.is_variable ast id   -> M.Mvarstorevar id
      | A.Pvar id when A.Utils.is_asset ast id      -> M.Mvarstorecol id
      | A.Pvar id when A.Utils.is_enum_value ast id -> M.Mvarenumval id
      | A.Pvar id                                   -> M.Mvarlocal id
      | A.Parray l                             -> M.Marray (List.map f l)
      | A.Plit ({node = BVint i; _})           -> M.Mint i
      | A.Plit ({node = BVuint i; _})          -> M.Muint i
      | A.Plit ({node = BVbool b; _})          -> M.Mbool b
      | A.Plit ({node = BVenum s; _})          -> M.Menum s
      | A.Plit ({node = BVrational (d, n); _}) -> M.Mrational (d, n)
      | A.Plit ({node = BVdate s; _})          -> M.Mdate s
      | A.Plit ({node = BVstring s; _})        -> M.Mstring s
      | A.Plit ({node = BVcurrency (c, i); _}) -> M.Mcurrency (i, to_currency c)
      | A.Plit ({node = BVaddress s; _})       -> M.Maddress s
      | A.Plit ({node = BVduration s; _})      -> M.Mduration s
      | A.Pdot (d, i)                          -> M.Mdot (f d, i)
      | A.Pconst Cstate                        -> M.Mstate
      | A.Pconst Cnow                          -> M.Mnow
      | A.Pconst Ctransferred                  -> M.Mtransferred
      | A.Pconst Ccaller                       -> M.Mcaller
      | A.Pconst Cbalance                      -> M.Mbalance
      | A.Pconst _                             -> assert false
      | A.Ptuple l                             -> M.Mtuple (List.map f l)
      | A.Lquantifer (Forall, i, typ, term)    -> M.Mforall (i, ltyp_to_type typ, f term)
      | A.Lquantifer (Exists, i, typ, term)    -> M.Mexists (i, ltyp_to_type typ, f term)

      | A.Pcall (_, A.Cconst A.Cbefore,    [AExpr p]) -> M.Msetbefore    (f p)
      | A.Pcall (_, A.Cconst A.Cunmoved,   [AExpr p]) -> M.Msetunmoved   (f p)
      | A.Pcall (_, A.Cconst A.Cadded,     [AExpr p]) -> M.Msetadded     (f p)
      | A.Pcall (_, A.Cconst A.Cremoved,   [AExpr p]) -> M.Msetremoved   (f p)
      | A.Pcall (_, A.Cconst A.Citerated,  [AExpr p]) -> M.Msetiterated  (f p)
      | A.Pcall (_, A.Cconst A.Ctoiterate, [AExpr p]) -> M.Msettoiterate (f p)

      | A.Pcall (aux, A.Cid id, args) ->
        M.Mapp (id, List.map (fun x -> term_arg_to_expr f x) args)

      | A.Pcall (Some p, A.Cconst A.Cget, [AExpr q]) ->
        M.Mget (f p, f q)

      | A.Pcall (Some p, A.Cconst (A.Ccontains), [AExpr q]) ->
        M.Mcontains (f p, f q)

      | A.Pcall (None, A.Cconst (A.Ccontains), [AExpr p; AExpr q]) ->
        M.Mcontains (f p, f q)

      | A.Pcall (None, A.Cconst (A.Csum), [AExpr p; AExpr q]) ->
        M.Msum (Location.dumloc "TODO", f q)

      | A.Pcall (Some p, A.Cconst (A.Csum), [AExpr q]) ->
        M.Msum (Location.dumloc "TODO", f q)

      | A.Pcall (None, A.Cconst (A.Cselect), [AExpr c; AExpr p]) ->
        M.Mselect (f c, f p)

      | A.Pcall (aux, A.Cconst c, args) ->
        Format.eprintf "expr const unkown: %a with nb args: %d %s@." A.pp_const c (List.length args) (match aux with | Some _ -> "with aux" | _ -> "without aux");
        assert false
  in

  let rec to_mterm (pterm : A.pterm) : M.mterm =
    let node = to_mterm_node pterm.node to_mterm ptyp_to_type in
    let type_ = ptyp_to_type (Option.get pterm.type_) in
    M.mk_mterm node type_ ~loc:pterm.loc
  in

  let rec lterm_to_mterm (lterm : A.lterm) : M.mterm =
    let node = to_mterm_node lterm.node lterm_to_mterm ltyp_to_type in
    let type_ = ltyp_to_type (Option.get lterm.type_) in
    M.mk_mterm node type_ ~loc:lterm.loc
  in

  let to_label_lterm (x : ('id, ('id, A.ltype_) A.term_gen) A.label_term) : M.label_term =
    M.mk_label_term (lterm_to_mterm x.term) ?label:x.label ~loc:x.loc
  in


  (* myasset.update k {f1 = v1; f2 = v2}

     let _k = k in
     let _myasset = myasset.get _k in
     myasset.f1 := v1;
     myasset.f2 := v2;
     set_myasset s _k _myasset *)

  let extract_letin (c : M.mterm) k (e : (A.lident * A.operator * M.mterm) list) : M.mterm__node =
    let extract_asset_name (pterm : M.mterm) : Ident.ident =
      match pterm with
      | {type_ = Tcontainer (Tasset asset_name, _); _ } -> unloc asset_name
      | _ -> assert false
    in

    let asset_name = extract_asset_name c in
    let asset_loced = dumloc asset_name in

    let type_asset = M.Tasset asset_loced in
    let type_container_asset = M.Tcontainer (type_asset, Collection) in

    let var_name = dumloc ("_" ^ asset_name) in
    let var_mterm : M.mterm = M.mk_mterm (M.Mvarlocal (dumloc (asset_name))) type_asset in

    let asset_mterm : M.mterm = M.mk_mterm (M.Mvarstorecol (dumloc (asset_name))) type_container_asset in

    let key_name = "_k" in
    let key_loced : M.lident = dumloc (key_name) in
    let key_mterm : M.mterm = M.mk_mterm (M.Mvarlocal key_loced) type_container_asset in

    let set_mterm : M.mterm = M.mk_mterm (M.Mset (asset_mterm, key_mterm, var_mterm)) Tunit in

    let seq : M.mterm list = (List.map (fun ((id, op, term) : ('a * A.operator * 'c)) -> M.mk_mterm
                                           (M.Massignfield (to_assign_operator op, var_name, id, term))
                                           Tunit
                                       ) e) @ [set_mterm] in

    let body : M.mterm = M.mk_mterm (M.Mseq seq) Tunit in

    let get_mterm : M.mterm = M.mk_mterm (M.Mget (asset_mterm, key_mterm)) type_asset in

    let letinasset : M.mterm = M.mk_mterm (M.Mletin (var_name,
                                                     get_mterm,
                                                     Some (type_asset),
                                                     body
                                                    ))
        Tunit in

    let res : M.mterm__node = M.Mletin (key_loced,
                                        key_mterm,
                                        None,
                                        letinasset
                                       ) in
    res

  in


  (* col.removeif pred

     let _pred = pred in
     let _col = col.select pred in
     for (_asset in _col)
       _col_asset.remove _asset.key
  *)

  (* let extract_removeif (c : M.mterm) (p : M.mterm) : M.mterm__node =

     let extract_ aaa = ()
     in



     let asset_name = extract_asset_name c in
     let asset_loced = dumloc asset_name in

     let type_asset = M.Tasset asset_loced in
     let type_container_asset = M.Tcontainer (type_asset, Collection) in

     let var_name = dumloc ("_" ^ asset_name) in
     let var_mterm : M.mterm = M.mk_mterm (M.Mvarlocal (dumloc (asset_name))) type_asset in

     let asset_mterm : M.mterm = M.mk_mterm (M.Mvarstorecol (dumloc (asset_name))) type_container_asset in

     let key_name = "_k" in
     let key_loced : M.lident = dumloc (key_name) in
     let key_mterm : M.mterm = M.mk_mterm (M.Mvarlocal key_loced) type_container_asset in

     let set_mterm : M.mterm = M.mk_mterm (M.Mset (None, asset_mterm, key_mterm, var_mterm)) Tunit in

     let seq : M.mterm list = (List.map (fun ((id, op, term) : ('a * A.operator * 'c)) -> M.mk_mterm
                                           (M.Massignfield (to_assign_operator op, var_name, id, term))
                                           Tunit
                                       ) e) @ [set_mterm] in

     let body : M.mterm = M.mk_mterm (M.Mseq seq) Tunit in

     let get_mterm : M.mterm = M.mk_mterm (M.Mget (None, asset_mterm, key_mterm)) type_asset in

     let letinasset : M.mterm = M.mk_mterm (M.Mletin (var_name,
                                                     get_mterm,
                                                     Some (type_asset),
                                                     body
                                                    ))
        Tunit in

     let res : M.mterm__node = M.Mletin (key_loced,
                                        key_mterm,
                                        None,
                                        letinasset
                                       ) in
     res

     in *)

  let to_instruction_node (n : (A.lident, A.ptyp, A.pterm, A.instruction) A.instruction_node) g f : ('id, 'instr) M.mterm_node =
    match n with
    | A.Iif (c, t, e)           -> M.Mif (f c, g t, g e)
    | A.Ifor (i, col, body)     -> M.Mfor (i, f col, g body)
    | A.Iletin (i, init, cont)  -> M.Mletin (i, f init, None, g cont) (* TODO *)
    | A.Iseq l                  -> M.Mseq (List.map g l)
    | A.Imatchwith (m, l)       -> M.Mmatchwith (f m, List.map (fun (p, i) -> (to_pattern p, g i)) l)
    | A.Iassign (op, i, e)      -> M.Massign (to_assignment_operator op, i, to_mterm e)
    | A.Irequire (b, t)         -> M.Mrequire (b, f t)
    | A.Itransfer (i, b, q)     -> M.Mtransfer (f i, b, Option.map to_qualid_gen q)
    | A.Ibreak                  -> M.Mbreak
    | A.Iassert e               -> M.Massert (f e)
    | A.Ireturn e               -> M.Mreturn (f e)
    | A.Icall (i, Cid id, args) -> M.Mapp (id, Option.map_dfl (fun v -> [to_mterm v]) [] i @ List.map (term_arg_to_expr f) args)

    | A.Icall (_, A.Cconst (A.Cfail), [AExpr p]) ->
      M.Mfail (f p)

    | A.Icall (None, A.Cconst (A.Cadd), [AExpr p; AExpr q]) ->
      M.Madd (f p, f q)

    | A.Icall (Some p, A.Cconst (A.Cadd), [AExpr q]) ->
      M.Madd (f p, f q)

    | A.Icall (None, A.Cconst (A.Cremove), [AExpr p; AExpr q]) ->
      M.Mremove (f p, f q)

    | A.Icall (Some p, A.Cconst (A.Cremove), [AExpr q]) ->
      M.Mremove (f p, f q)

    | A.Icall (Some p, A.Cconst (A.Cupdate), [AExpr k; AEffect e]) ->
      let p = f p in
      let k = f k in
      let e = List.map (fun (a, b, c) -> (a, b, f c)) e in
      extract_letin p k e

    | A.Icall (None, A.Cconst (A.Cselect), [AExpr p; AExpr q]) ->
      M.Mselect (f p, f q)

    | A.Icall (Some c, A.Cconst (A.Cremoveif), [AExpr p]) ->
      M.Mseq []
    (* extract_removeif (f c) (f p) *)

    | A.Icall (aux, A.Cconst c, args) ->
      Format.eprintf "instr const unkown: %a with nb args: %d %s@." A.pp_const c (List.length args) (match aux with | Some _ -> "with aux" | _ -> "without aux");
      assert false
  in

  let rec to_instruction (instr : A.instruction) : M.mterm =
    let node = to_instruction_node instr.node to_instruction to_mterm in
    M.mk_mterm node (M.Tunit) ~subvars:instr.subvars ~loc:instr.loc
  in

  let to_predicate (p : ('a, A.ptyp) A.predicate) : M.predicate =
    M.mk_predicate p.name (lterm_to_mterm p.body) ~args:(List.map (fun (id, body) -> (id, lterm_to_mterm body)) p.args) ~loc:p.loc
  in

  let to_definition (d : ('a, A.ptyp) A.definition ): M.definition =
    M.mk_definition d.name (ptyp_to_type d.typ) d.var (lterm_to_mterm d.body) ~loc:d.loc
  in

  let to_variable (v : (A.lident, A.ptyp, A.pterm) A.variable) : M.variable =
    M.mk_variable
      ((fun (arg : (A.lident, A.ptyp, A.pterm) A.decl_gen) : (M.lident * M.type_ * M.mterm option) ->
          (arg.name, ptyp_to_type (Option.get arg.typ), Option.map to_mterm arg.default)) v.decl)
      ~constant:v.constant
      ?from:(Option.map to_qualid_gen v.from)
      ?to_:(Option.map to_qualid_gen v.to_)
      ~loc:v.loc
  in

  let to_invariant (i : (A.lident, A.ptyp) A.invariant) :M.invariant  =
    M.mk_invariant i.label ~formulas:(List.map lterm_to_mterm i.formulas)
  in

  let to_spec (s : (A.lident, A.type_) A.specification) : M.specification  =
    M.mk_specification s.name (lterm_to_mterm s.formula) ~invariants:(List.map to_invariant s.invariants)
  in

  let to_assert (a : (A.lident, A.type_) A.assert_) : M.assert_  =
    M.mk_assert a.name a.label (lterm_to_mterm a.formula) ~invariants:(List.map to_invariant a.invariants)
  in

  let to_verification (v : (A.lident, A.ptyp, A.pterm) A.verification) : M.verification =
    let predicates  = List.map to_predicate   v.predicates  in
    let definitions = List.map to_definition  v.definitions in
    let axioms      = List.map to_label_lterm v.axioms      in
    let theorems    = List.map to_label_lterm v.theorems    in
    let variables   = List.map (fun x -> to_variable x) v.variables in
    let invariants  = List.map (fun (a, l) -> (a, List.map (fun x -> to_label_lterm x) l)) v.invariants in
    let effects     = Option.map_dfl (fun x -> [to_mterm x]) [] v.effect in
    let specs       = List.map to_spec        v.specs       in
    let asserts     = List.map to_assert      v.asserts     in
    M.mk_verification
      ~predicates:predicates
      ~definitions:definitions
      ~axioms:axioms
      ~theorems:theorems
      ~variables:variables
      ~invariants:invariants
      ~effects:effects
      ~specs:specs
      ~asserts:asserts
      ~loc:v.loc ()
  in

  let cont_verification (v : (A.lident, A.ptyp, A.pterm) A.verification) (verif : M.verification) : M.verification =
    let v = to_verification v in
    { verif with
      predicates  = verif.predicates @ v.predicates;
      definitions = verif.definitions @ v.definitions;
      axioms      = verif.axioms @ v.axioms;
      theorems    = verif.theorems @ v.theorems;
      variables   = verif.variables @ v.variables;
      invariants  = verif.invariants @ v.invariants;
      effects     = verif.effects @ v.effects;
      specs       = verif.specs @ v.specs;
      asserts     = verif.asserts @ v.asserts;
      loc         = Location.merge verif.loc v.loc;
    }
  in

  let process_enums list =
    let process_enum (e : A.enum) : M.decl_node =
      let values = List.map (fun (x : (A.lident, A.type_, A.pterm) A.enum_item_struct) ->
          let id : M.lident = x.name in
          M.mk_enum_item id ~invariants:(List.map (fun x -> to_label_lterm x) x.invariants)
        ) e.items in
      let enum = M.mk_enum e.name ~values:values in
      M.Denum enum
    in
    list @ List.map (fun x -> process_enum x) ast.enums in

  let process_records list =
    let process_asset (a : A.asset) : M.decl_node =
      let values = List.map (fun (x : (A.lident, A.type_, A.pterm) A.decl_gen) ->
          let typ = Option.map ptyp_to_type x.typ in
          let default = Option.map to_mterm x.default in
          M.mk_record_item x.name (Option.get typ) ?default:default) a.fields in
      let r : M.record = M.mk_record a.name ?key:a.key ~values:values in
      M.Drecord r
    in
    list @ List.map (fun x -> process_asset x) ast.assets
  in

  let process_contracts list =
    let to_contract_signature (s : (A.lident, A.ptyp) A.signature) : M.contract_signature =
      let name = s.name in
      M.mk_contract_signature name ~args:(List.map (fun arg -> ptyp_to_type arg) s.args) ~loc:s.loc
    in
    let to_contract (c : (A.lident, A.ptyp, A.pterm) A.contract) : M.contract =
      M.mk_contract c.name
        ~signatures:(List.map to_contract_signature c.signatures)
        ?init:(Option.map to_mterm c.init)
        ~loc:c.loc
    in
    list @ List.map (fun (x : (A.lident, A.ptyp, A.pterm) A.contract) -> M.Dcontract (to_contract x)) ast.contracts
  in

  let process_storage list =
    let variable_to_storage_items (var : (A.lident, A.type_, A.pterm) A.variable) : M.storage_item =
      let arg = var.decl in
      let compute_field (type_ : A.type_) : M.item_field =
        let rec ptyp_to_item_field_type = function
          | A.Tbuiltin vtyp -> M.FBasic (vtyp_to_btyp vtyp)
          | A.Tenum id      -> M.FEnum id
          | A.Tasset id     -> M.FRecord id
          | A.Tcontract x   -> M.FBasic Brole
          | A.Tcontainer (ptyp, container) -> M.FContainer (to_container container, ptyp_to_item_field_type ptyp)
          | A.Tentry
          | A.Toption _
          | A.Ttuple _      -> emit_error (UnsupportedTypeForFile type_)
        in
        let a = ptyp_to_item_field_type type_ in
        M.mk_item_field arg.name a ?default:(Option.map to_mterm arg.default)
      in

      let storage_item = M.mk_storage_item arg.name in
      let typ : A.type_ = Option.get arg.typ in {
        storage_item with
        fields = [compute_field typ];
      }
    in

    let asset_to_storage_items (asset : A.asset) : M.storage_item =
      let asset_name = asset.name in
      let compute_fields =
        let _, key_type = A.Utils.get_asset_key ast asset_name in
        let key_asset_name = Location.mkloc (Location.loc asset_name) ((Location.unloc asset_name) ^ "_keys") in
        let map_asset_name = Location.mkloc (Location.loc asset_name) ((Location.unloc asset_name) ^ "_assets") in
        [M.mk_item_field key_asset_name (FAssetKeys (vtyp_to_btyp key_type, asset_name))
           ~asset:asset_name
        (*?default:None TODO: uncomment this*);
         M.mk_item_field map_asset_name (FAssetRecord (vtyp_to_btyp key_type, asset_name))
           ~asset:asset_name
           (* ~default:arg.default TODO: uncomment this*)] in
      M.mk_storage_item asset.name
        ~fields:compute_fields
        ~invariants:(List.map (fun x -> to_label_lterm x) asset.specs)
    in

    let cont f x l = l @ (List.map f x) in
    []
    |> cont variable_to_storage_items ast.variables
    |> cont asset_to_storage_items ast.assets
  in

  let cont f x l = List.fold_left (fun accu x -> f x accu) l x in

  let process_fun_gen name args (body : M.mterm) loc verif f (list : M.function__ list) : M.function__ list =
    let node = f (M.mk_function_struct name body
                    ~args:args
                    ~loc:loc) in
    list @ [M.mk_function ?verif:verif node]
  in

  let process_function (function_ : A.function_) (list : M.function__ list) : M.function__ list =
    let name  = function_.name in
    let args  = List.map (fun (x : (A.lident, A.ptyp, A.ptyp A.bval_gen) A.decl_gen) -> (x.name, (ptyp_to_type |@ Option.get) x.typ, None)) function_.args in
    let body  = to_instruction function_.body in
    let loc   = function_.loc in
    let ret   = ptyp_to_type function_.return in
    let verif : M.verification option = Option.map to_verification function_.verification in
    process_fun_gen name args body loc verif (fun x -> M.Function (x, ret)) list
  in

  let process_transaction (transaction : A.transaction) (list : M.function__ list) : M.function__ list =
    let list  = list |> cont process_function ast.functions in
    let name  = transaction.name in
    let args  = List.map (fun (x : (A.lident, A.ptyp, A.ptyp A.bval_gen) A.decl_gen) -> (x.name, (ptyp_to_type |@ Option.get) x.typ, None)) transaction.args in
    let body  = (to_instruction |@ Option.get) transaction.effect in
    let loc   = transaction.loc in
    let verif : M.verification option = Option.map to_verification transaction.verification in
    process_fun_gen name args body loc verif (fun x -> M.Entry x) list
  in

  let process_api_storage (model : M.model) : M.model =
    let add l i =
      let e = List.fold_left (fun accu x ->
          if x = i
          then true
          else accu) false l in
      if e then
        l
      else
        i::l
    in

    let ge (e : M.mterm) = (fun node -> { e with node = node }) in

    let rec fe (accu : M.api_item list) (term : M.mterm) : M.mterm * M.api_item list =
      match term.node with
      | M.Mget ({node = M.Mvarstorecol asset_name; _}, _) ->
        let api_item = M.APIStorage (M.Get asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mset ({node = M.Mvarstorecol asset_name; _}, _, _) ->
        let api_item = M.APIStorage (M.Set asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Madd ({node = M.Mvarstorecol asset_name; _}, _) ->
        let api_item = M.APIStorage (M.Add asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Madd ({node = M.Mdot ({type_ = M.Tasset asset_name ; _}, f); _}, _) ->
        let api_item = M.APIStorage (M.UpdateAdd (asset_name, f)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mremove ({node = M.Mvarstorecol asset_name; _}, _) ->
        let api_item = M.APIStorage (M.Remove asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mremove ({node = M.Mdot ({type_ = M.Tasset asset_name ; _}, f); _}, _) ->
        let api_item = M.APIStorage (M.UpdateRemove (asset_name, f)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mclear ({node = M.Mvarstorecol asset_name; _}) ->
        let api_item = M.APIStorage (M.Clear asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mclear ({node = M.Mdot ({type_ = M.Tasset asset_name ; _}, f); _}) ->
        let api_item = M.APIStorage (M.UpdateClear (asset_name, f)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mreverse ({node = M.Mvarstorecol asset_name; _}) ->
        let api_item = M.APIStorage (M.Reverse asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mreverse ({node = M.Mdot ({type_ = M.Tasset asset_name ; _}, f); _}) ->
        let api_item = M.APIStorage (M.UpdateReverse (asset_name, f)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mselect ({node = M.Mvarstorecol asset_name; _}, _) ->
        let api_item = M.APIFunction (M.Select asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Msort ({node = M.Mvarstorecol asset_name; _}, field_name, _) ->
        let api_item = M.APIFunction (M.Sort (asset_name, field_name)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mcontains ({type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}, _) ->
        let api_item = M.APIFunction (M.Contains asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mnth ({type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}, _) ->
        let api_item = M.APIFunction (M.Nth asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mcount ({type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}) ->
        let api_item = M.APIFunction (M.Count asset_name) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Msum (field_name, {type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}) ->
        let api_item = M.APIFunction (M.Sum (asset_name, field_name)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mmin (field_name, {type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}) ->
        let api_item = M.APIFunction (M.Min (asset_name, field_name)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu
      | M.Mmax (field_name, {type_ = M.Tcontainer (M.Tasset asset_name, _) ; _}) ->
        let api_item = M.APIFunction (M.Max (asset_name, field_name)) in
        let term, accu = M.fold_map_term (ge term) fe accu term in
        let accu = add accu (Model.mk_api_item api_item) in
        term, accu

      | _ -> M.fold_map_term (ge term) fe accu term in

    let process_mterm (accu : M.api_item list) (expr : M.mterm) : M.mterm * M.api_item list =
      fe accu expr
    in

    let update_label_term accu (lt : M.label_term) : M.label_term * M.api_item list =
      let t, accu = process_mterm accu lt.term in
      { lt with term = t }, accu
    in

    let update_predicate accu (d : M.predicate) : M.predicate * M.api_item list =
      let body, accu = process_mterm accu d.body in
      { d with body = body }, accu
    in

    let update_definition accu (d : M.definition) : M.definition * M.api_item list =
      let body, accu = process_mterm accu d.body in
      { d with body = body }, accu
    in

    let update_invariant accu (i : M.invariant) : M.invariant * M.api_item list =
      let formulas, accu = List.fold_left
          (fun (l, accu) item ->
             let i, accu = process_mterm accu item in
             (l @ [i], accu)
          ) ([], accu) i.formulas in
      { i with formulas = formulas }, accu
    in

    let update_specification accu (spec : M.specification) : M.specification * M.api_item list =
      let formula, accu = process_mterm accu spec.formula in
      let invariants, accu = List.fold_left
          (fun (l, accu) (item : M.invariant) ->
             let i, accu = update_invariant accu item in
             (l @ [i], accu)
          ) ([], accu) spec.invariants in
      { spec with formula = formula; invariants = invariants; }, accu
    in

    let update_assert accu (assert_ : M.assert_) : M.assert_ * M.api_item list =
      let formula, accu = process_mterm accu assert_.formula in
      let invariants, accu = List.fold_left
          (fun (l, accu) (item : M.invariant) ->
             let i, accu = update_invariant accu item in
             (l @ [i], accu)
          ) ([], accu) assert_.invariants in
      { assert_ with formula = formula; invariants = invariants; }, accu
    in

    let update_verif accu (verif : M.verification) : M.verification * M.api_item list =

      let predicates, accu = List.fold_left
          (fun (l, accu) (item : M.predicate) ->
             let i, accu = update_predicate accu item in
             (l @ [i], accu)
          ) ([], accu) verif.predicates in

      let definitions, accu = List.fold_left
          (fun (l, accu) (item : M.definition) ->
             let i, accu = update_definition accu item in
             (l @ [i], accu)
          ) ([], accu) verif.definitions in

      let axioms, accu = List.fold_left
          (fun (l, accu) (item : M.label_term) ->
             let i, accu = update_label_term accu item in
             (l @ [i], accu)
          ) ([], accu) verif.axioms in

      let theorems, accu = List.fold_left
          (fun (l, accu) (item : M.label_term) ->
             let i, accu = update_label_term accu item in
             (l @ [i], accu)
          ) ([], accu) verif.theorems in

      let invariants, accu =
        List.fold_left (fun (l, accu) (lbl, is) ->
            let invs, accu = List.fold_left
                (fun (l, accu) (item : M.label_term) ->
                   let i, accu = update_label_term accu item in
                   (l @ [i], accu)
                ) ([], accu) is in
            (l @ [lbl, invs], accu)
          ) ([], accu) verif.invariants in

      let effects, accu = List.fold_left
          (fun (l, accu) (item : M.mterm) ->
             let i, accu = process_mterm accu item in
             (l @ [i], accu)
          ) ([], accu) verif.effects in

      let specs, accu = List.fold_left
          (fun (l, accu) (item : M.specification) ->
             let i, accu = update_specification accu item in
             (l @ [i], accu)
          ) ([], accu) verif.specs in

      let asserts, accu = List.fold_left
          (fun (l, accu) (item : M.assert_) ->
             let i, accu = update_assert accu item in
             (l @ [i], accu)
          ) ([], accu) verif.asserts in

      { verif with
        predicates  = predicates;
        definitions = definitions;
        axioms      = axioms;
        theorems    = theorems;
        (* variables   : 'id variable_gen list; *)
        invariants  = invariants;
        effects     = effects;
        specs       = specs;
        asserts     = asserts;
      }, accu
    in

    let update_function_struct accu (fs : M.function_struct) : M.function_struct * M.api_item list =
      let instr, accu = process_mterm accu fs.body in
      { fs with body = instr}, accu
    in

    let update_function__ (f : M.function__) (fs : M.function_struct) accu g : M.function__  * M.api_item list =
      let fs, accu = update_function_struct accu fs in
      let verif, accu =
        match f.verif with
        | Some v -> update_verif accu v |> (fun (x, y) -> Some x, y)
        | _ -> None, accu
      in
      { f with node = g fs; verif = verif }, accu
    in

    let api_items : M.api_item list = model.api_items in

    let (functions, api_items) : M.function__ list * M.api_item list =
      List.fold_left
        (fun ((accu, api_items) : M.function__ list * M.api_item list) (f : M.function__) ->
           match f.node with
           | M.Entry e ->
             begin
               let f, api_items = update_function__ f e api_items (fun e -> Entry e) in
               accu @ [f], api_items
             end
           | M.Function (e, t) ->
             begin
               let f, api_items = update_function__ f e api_items (fun e -> Function (e, t)) in
               accu @ [f], api_items
             end
             (* | _ -> accu @ [f], api_items *)
        ) ([], api_items) model.functions in

    let (v, api_items) : M.verification * M.api_item list = update_verif api_items model.verification in

    {
      model with
      api_items = api_items;
      functions = functions;
      verification = v;
    }

  in

  let name = ast.name in
  let decls =
    []
    |> process_enums
    |> process_records
    |> process_contracts
  in

  let storage_items = process_storage () in
  let storage = storage_items in

  let functions =
    []
    |> cont process_function ast.functions
    |> cont process_transaction ast.transactions
  in

  let verification =
    M.mk_verification ()
    |> (fun verif -> List.fold_left (fun accu x -> cont_verification x accu) verif ast.verifications)
  in

  M.mk_model name storage verification ~decls:decls ~functions:functions
  |> process_api_storage
