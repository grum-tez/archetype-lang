(* opening the Why3 library *)
open Why3
open Format
open Model
open Miles

(* helper function: [use th1 th2] insert the equivalent of a
   "use import th2" in theory th1 under construction *)
let use th1 th2 =
  let name = th2.Theory.th_name in
  Theory.close_scope
    (Theory.use_export (Theory.open_scope th1 name.Ident.id_string) th2)
    ~import:true

let add_use env theory =
  let int_theory = Env.read_theory env ["int"] "Int" in
  (*let int_theory : Theory.theory = Env.read_theory env ["mach";"int"] "UInt32" in*)
  let ref_theory = Env.read_theory env ["ref"] "Ref" in
  let fset_theory = Env.read_theory env ["set"] "Fset" in
  let fsetsum_theory = Env.read_theory env ["set"] "FsetSum" in
  let array_theory = Env.read_theory env ["array"] "Array" in
  let types_theory = Env.read_theory env ["cml"] "Types" in
  let contract_theory = Env.read_theory env ["cml"] "Contract" in
  let ngmap_theory = Env.read_theory env ["cml"] "Ngmap" in
  let theory = use theory int_theory in
  let theory = use theory ref_theory in
  let theory = use theory fset_theory in
  let theory = use theory fsetsum_theory in
  let theory = use theory array_theory in
  let theory = use theory types_theory in
  let theory = use theory contract_theory in
  let theory = use theory ngmap_theory in
  theory

(*let add_types theory m =
  let
  let decl = Decl.create_data_decl [] in
  Theory.add_decl theory decl*)

let mk_loadpath main = (Whyconf.loadpath main) @ ["/home/dev/cml/models/why3tests/"]

let mk_theory (m : model) =
 let config : Whyconf.config = Whyconf.read_config None in
 let main : Whyconf.main = Whyconf.get_main config in
 let main = Whyconf.set_loadpath main (mk_loadpath main) in
 let env : Env.env = Env.create_env (Whyconf.loadpath main) in
 let theory = Theory.create_theory (Ident.id_fresh m.name) in
 let theory = add_use env theory in
 Theory.close_theory theory

let config : Whyconf.config = Whyconf.read_config None
let main : Whyconf.main = Whyconf.get_main config
let env : Env.env = Env.create_env (Whyconf.loadpath main)

let my_theory : Theory.theory_uc =
  Theory.create_theory (Ident.id_fresh "My_theory")

(* a ground propositional goal: true or false *)
let fmla_true : Term.term = Term.t_true
let fmla_false : Term.term = Term.t_false
let fmla1 : Term.term = Term.t_or fmla_true fmla_false

let prop_var_A : Term.lsymbol =
  Term.create_psymbol (Ident.id_fresh "A") []
let prop_var_B : Term.lsymbol =
  Term.create_psymbol (Ident.id_fresh "B") []
let atom_A : Term.term = Term.ps_app prop_var_A []
let atom_B : Term.term = Term.ps_app prop_var_B []
let fmla2 : Term.term =
  Term.t_implies (Term.t_and atom_A atom_B) atom_A

let two  : Term.term = Term.t_nat_const 2
let four : Term.term = Term.t_nat_const 4
let int_theory : Theory.theory = Env.read_theory env ["int"] "Int"
let plus_symbol : Term.lsymbol =
  Theory.ns_find_ls int_theory.Theory.th_export ["infix +"]
let two_plus_two : Term.term = Term.t_app_infer plus_symbol [two;two]
let fmla3 : Term.term = Term.t_equ two_plus_two four

let zero : Term.term = Term.t_nat_const 0
let mult_symbol : Term.lsymbol =
  Theory.ns_find_ls int_theory.Theory.th_export ["infix *"]
let ge_symbol : Term.lsymbol =
  Theory.ns_find_ls int_theory.Theory.th_export ["infix >="]
let var_x : Term.vsymbol =
  Term.create_vsymbol (Ident.id_fresh "x") Ty.ty_int
let x : Term.term = Term.t_var var_x
let x_times_x : Term.term = Term.t_app_infer mult_symbol [x;x]
let fmla4_aux : Term.term = Term.ps_app ge_symbol [x_times_x;zero]
let fmla4 : Term.term = Term.t_forall_close [var_x] [] fmla4_aux

let goal_id1 = Decl.create_prsymbol (Ident.id_fresh "goal1")
let goal_id2 = Decl.create_prsymbol (Ident.id_fresh "goal2")
let goal_id3 = Decl.create_prsymbol (Ident.id_fresh "goal3")
let goal_id4 = Decl.create_prsymbol (Ident.id_fresh "goal4")

let decl_goal1 : Decl.decl =
  Decl.create_prop_decl Decl.Pgoal goal_id1 fmla1
let my_theory : Theory.theory_uc = Theory.add_decl my_theory decl_goal1

let my_theory : Theory.theory_uc =
  Theory.add_param_decl my_theory prop_var_A
let my_theory : Theory.theory_uc =
  Theory.add_param_decl my_theory prop_var_B
let decl_goal2 : Decl.decl =
  Decl.create_prop_decl Decl.Pgoal goal_id2 fmla2
let my_theory : Theory.theory_uc = Theory.add_decl my_theory decl_goal2

(* helper function: [use th1 th2] insert the equivalent of a
   "use import th2" in theory th1 under construction *)
let use th1 th2 =
  let name = th2.Theory.th_name in
  Theory.close_scope
    (Theory.use_export (Theory.open_scope th1 name.Ident.id_string) th2)
    ~import:true

let int_theory : Theory.theory = Env.read_theory env ["int"] "Int"

let my_theory : Theory.theory_uc = use my_theory int_theory
let decl_goal3 : Decl.decl =
  Decl.create_prop_decl Decl.Pgoal goal_id3 fmla3
let my_theory : Theory.theory_uc = Theory.add_decl my_theory decl_goal3

let decl_goal4 : Decl.decl =
  Decl.create_prop_decl Decl.Pgoal goal_id4 fmla4
let my_theory : Theory.theory_uc = Theory.add_decl my_theory decl_goal4

let my_theory : Theory.theory = Theory.close_theory my_theory

let pr_theo theo = printf "@[my new theory is as follows:@\n@\n%a@]@."
              Pretty.print_theory theo

let _ =
  pr_theo my_theory;
  pr_theo (mk_theory (mk_miles_model ()))