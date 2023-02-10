open Ast.Impl

type element_type =
  | Inline
  | Block
  | Table

type t =
  | Element of element_type * string * attributes * t option
  | Text of string
  | Raw of string
  | Null
  | Concat of t * t

val htmlentities : string -> string
val of_doc : attributes block list -> t
val to_string : t -> string
