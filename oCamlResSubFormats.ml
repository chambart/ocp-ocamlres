(* This file is part of ocp-ocamlres - directory scanning
 * (C) 2013 OCamlPro - Benjamin CANOU
 *
 * ocp-ocamlres is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * ocp-ocamlres is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ocp-ocamlres.  If not, see <http://www.gnu.org/licenses/>. *)

module type SubFormat = sig
  type t
  val parse : string -> t
  val output : out_channel -> t -> unit
  val name : string
  val ty : string
  val info : string
  val options : (Arg.key * Arg.spec * Arg.doc) list
end

module SM = Map.Make (String)
let subformats = ref (SM.empty : (module SubFormat) SM.t)
    
let register m =
  let module M = (val m : SubFormat) in
  subformats := SM.add M.name m !subformats
      
let find n =
  SM.find n !subformats

(** A probably useless subformat, for demonstration purposes *)
module Int = struct
  type t = int
  let parse str =
    Scanf.sscanf str "%i" (fun i -> i)

  let output fp i = Printf.fprintf fp "%i" i
  let name = "int" and ty = "int"
  let info = "files containing only an integer"
  let options = []
end

let _ = register (module Int : SubFormat)

(** Functions to be used by format implementations *)
let handled_subformats, options =
  (* the following lists are separated because of Arg limitations *)
  let sf_exts = ref [] in
  let sf_mods = ref [] in
  let handled_subformats () =
    let sfs = List.combine !sf_exts !sf_mods in
    List.fold_left
      (fun r (ext, n) ->
         try
           SM.add ext (SM.find n !subformats) r
         with Not_found ->
           Printf.eprintf "Subformat %s not found.\n%!" n ;
           exit 1
      )
      SM.empty sfs
  in
  let options =
    [ "-subformat", Arg.(Tuple [ String (fun e -> sf_exts := e :: !sf_exts) ;
                                 String (fun e -> sf_mods := e :: !sf_mods) ]),
      "\"ext\" \"subformat\"&preprocess files ending with \"ext\" as \"suformat\"" ]
  in 
  handled_subformats, options

(** Retrive the currently available subformats *)
let subformats () =
  List.map
    (fun (n, m) ->
       let module M = (val m : SubFormat) in
       n, M.info, M.options)
    (SM.bindings !subformats)
