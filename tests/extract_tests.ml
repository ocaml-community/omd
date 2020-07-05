(* Extract test cases from Spec *)

let disabled =
  [
    164;
    175;
    184;
    185;
    334;
    353;
    410;
    411;
    414;
    415;
    416;
    428;
    468;
    469;
    486;
    516;
    536;
    570;
    519;
    591;
  ]

let with_open_in fn f =
  let ic = open_in fn in
  let result = f ic in
  close_in_noerr ic;
  result



let with_open_out fn f =
  let oc = open_out fn in
  let result = f oc in
  close_out oc;
  result

let begins_with s s' =
  String.length s >= String.length s' &&
  String.sub s 0 (String.length s') = s'

let test_delim = "````````````````````````````````"

let tab_re = Str.regexp_string "→"

let insert_tabs s =
  Str.global_replace tab_re "\t" s

type test =
  {
    example: int;
    markdown: string;
    html: string;
  }

let add_line buf l =
  Buffer.add_string buf (insert_tabs l);
  Buffer.add_char buf '\n'

let spec = "spec.txt"

let tests =
  let buf = Buffer.create 256 in
  with_open_in spec @@ fun ic ->
  let rec go tests example =
    match input_line ic with
    | exception End_of_file ->
        List.rev tests
    | line ->
        if begins_with line test_delim then begin
          Buffer.clear buf;
          let rec get_test () =
            let line = input_line ic in
            if line = "." then begin
              let markdown = Buffer.contents buf in
              Buffer.clear buf;
              let rec get_html () =
                let line = input_line ic in
                if begins_with line test_delim then
                  let html = Buffer.contents buf in
                  {example; markdown; html}
                else begin
                  add_line buf line;
                  get_html ()
                end
              in
              get_html ()
            end else begin
              add_line buf line;
              get_test ()
            end
          in
          go (get_test () :: tests) (succ example)
        end else
          go tests example
  in
  go [] 1

let write_dune_file () =
  let pp ppf {example; _} =
    Format.fprintf ppf "@ spec-%03d.md spec-%03d.html" example example
  in
  Format.printf
    "@[<v1>(rule@ @[<hov1>(deps %s)@]@ @[<v1>(targets%t)@]@ @[<hov1>(action@ (run ./extract_tests.exe -generate-test-files))@])@]@." spec
    (fun ppf -> List.iter (pp ppf) tests);
  List.iter (fun {example; _} ->
      Format.printf
        "@[<v1>(rule@ @[<hov1>(action@ @[<hov1>(with-stdout-to spec-%03d.html.new@ @[<hov1>(run@ ./omd.exe@ %%{dep:spec-%03d.md})@])@])@])@]@." example example;
      Format.printf
        "@[<v1>(rule@ @[<hov1>(alias spec-%03d)@]@ @[<hov1>(action@ @[<hov1>(diff@ spec-%03d.html spec-%03d.html.new)@])@])@]@." example example example
    ) tests;
  let pp ppf {example; _} =
    if not (List.mem example disabled) then
      Format.fprintf ppf "@ (alias spec-%03d)" example in
  Format.printf
    "@[<v1>(alias@ (name runtest)@ @[<v1>(deps%t)@])@]@."
    (fun ppf -> List.iter (pp ppf) tests)

let li_begin_re = Str.regexp_string "<li>\n"
let li_end_re = Str.regexp_string "\n</li>"

let normalize_html s =
  Str.global_replace li_end_re "</li>"
    (Str.global_replace li_begin_re "<li>" s)

let generate_test_files () =
  let f {example; markdown; html} =
    with_open_out (Printf.sprintf "spec-%03d.md" example)
      (fun oc -> output_string oc markdown);
    with_open_out (Printf.sprintf "spec-%03d.html" example)
      (fun oc -> output_string oc (normalize_html html))
  in
  List.iter f tests

let spec =
  [
    "-generate-test-files", Arg.Unit generate_test_files, " Generate test files";
    "-write-dune-file", Arg.Unit write_dune_file, " Write dune file";
  ]

let () =
  Arg.parse (Arg.align spec) ignore ""
