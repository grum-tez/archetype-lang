open Tools

module A = Model
module M = Storage

type enum_item_struct = (A.lident, A.type_, A.pterm) A.enum_item_struct
type verification     = (A.lident, A.type_, A.pterm) A.verification
type record           = (A.lident, A.type_, A.pterm) A.decl_gen
type field            = (A.lident, A.type_, A.pterm) A.decl_gen
type variable         = (A.lident, A.type_, A.pterm) A.variable

let ast_to_model (ast : A.model) : M.model =
  let process_enums list =
    let process_enum (e : A.enum) : M.type_node =
      let enum = M.mk_enum e.name in
      M.TNenum {
        enum with
        values = List.map (fun (x : enum_item_struct) ->
            let id : M.lident = x.name in
            let enum_item = M.mk_enum_item id in
            {
              enum_item with
              invariants = map_option_neutral (fun (x : verification) -> x.specs) [] x.verification;
            }
          ) e.items;
      }
    in
    list @ List.map (fun x -> process_enum x) ast.enums in

  let process_records list =
    let process_asset (a : A.asset) : M.type_node =
      let e = M.mk_record a.name in
      M.TNrecord {
        e with
        values = List.map (fun (x : (A.lident, A.type_, A.pterm) A.decl_gen) -> M.mk_record_item x.name (get x.typ)) a.fields;
      }
    in
    list @ List.map (fun x -> process_asset x) ast.assets in

  let process_storage list =
    let variable_to_storage_items (var : variable) : M.storage_item =
      let arg = var.decl in
      let compute_field (type_ : A.type_) : M.item_field =
        let rec ptyp_to_item_field_type = function
          | A.Tbuiltin vtyp -> M.FBasic vtyp
          | A.Tenum id      -> M.FEnum id
          | A.Tasset id     -> M.FRecord id
          | A.Tcontainer (ptyp, container) -> M.FContainer (container, ptyp_to_item_field_type ptyp)
          | A.Ttuple _ -> assert false
        in
        let a = ptyp_to_item_field_type type_ in
        let item_field =
          let m = M.mk_item_field arg.name a in
          { m with default = arg.default } in
        item_field

      in

      let storage_item = M.mk_storage_item arg.name in
      let typ : A.type_ = get arg.typ in {
        storage_item with
        fields = [compute_field typ];
        init = [];
      }
    in

    let asset_to_storage_items (asset : A.asset) : M.storage_item =
      let id = asset.name in
      let compute_fields =
        let type_id : A.vtyp =
          let res : A.vtyp option = List.fold_left (fun accu (x : field) ->
              if String.equal (Location.unloc x.name) (Location.unloc (get asset.key))
              then (
                match x.typ with
                | Some (Tbuiltin v) -> Some v
                | _ -> accu
              )
              else accu
            ) None asset.fields in
          match res with
          | Some t -> t
          | _ -> get res
        in
        let mk a =
          let m = M.mk_item_field id a in
          { m with
            asset = Some id;
            (* default = arg.default; *)
          } in
        let asset_name = id in
        let keys_id = Location.mkloc (Location.loc asset_name) ((Location.unloc asset_name) ^ "_keys") in
        let asset_name = Location.mkloc (Location.loc asset_name) ((Location.unloc asset_name) ^ "_assets") in
        [mk (FKeyCollection (keys_id, type_id)); mk (FRecordMap asset_name)] in
      let item = M.mk_storage_item asset.name in
      { item with
        fields = compute_fields;
        invariants = asset.specs;
        (* init = asset.init; *)
      }
    in

    let cont f x l = List.map f x in
    []
    |> cont variable_to_storage_items ast.variables
    |> cont asset_to_storage_items ast.assets
    |> (fun x -> list @ [M.TNstorage x])
  in

  []
  |> process_enums
  |> process_records
  |> process_storage