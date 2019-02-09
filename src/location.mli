(* -------------------------------------------------------------------- *)
open Lexing

(* -------------------------------------------------------------------- *)
type t = {
  loc_fname : string;
  loc_start : int * int;
  loc_end   : int * int;
  loc_bchar : int;
  loc_echar : int;
}

(* -------------------------------------------------------------------- *)
val dummy     : t
val isdummy   : t -> bool
val make      : position -> position -> t
val of_lexbuf : lexbuf -> t

val merge    : t -> t -> t
val mergeall : t list -> t

val tostring : t -> string

(* -------------------------------------------------------------------- *)
type 'a loced = {
  plloc : t;
  pldesc : 'a;
}

val pp_loced : (Format.formatter -> 'a -> unit) -> Format.formatter -> 'a loced -> unit
val mkloc   : t -> 'a -> 'a loced
val loc     : 'a loced -> t
val unloc   : 'a loced -> 'a
val unlocs  : ('a loced) list -> 'a list
val lmap    : ('a -> 'b) -> 'a loced -> 'b loced
val dumloc  : 'a -> 'a loced