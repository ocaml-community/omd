(***********************************************************************)
(* omd: Markdown frontend in OCaml                                     *)
(* (c) 2013 by Philippe Wang <philippe.wang@cl.cam.ac.uk>              *)
(* Licence : CeCILL-B                                                  *)
(* http://www.cecill.info/licences/Licence_CeCILL-B_V1-en.html         *)
(***********************************************************************)

include Omd_backend

type token = Omd_parser.tag Omd_lexer.t

let lex : string -> token list = Omd_lexer.lex

let parse : token list -> t = Omd_parser.parse

let html_of_md : t -> string = html_of_md

let html_of_string (html:string) : string =
  html_of_md (parse (lex html))




