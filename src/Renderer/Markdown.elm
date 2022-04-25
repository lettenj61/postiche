module Renderer.Markdown exposing (..)

import Elm.Docs as Docs exposing (Alias, Union)
import Elm.Type as Type


type alias Printer a =
    { signature : Maybe (a -> String)
    , comment : a -> String
    }


printWith : a -> Printer a -> String
printWith data printer =
    String.join "\n" <|
        List.filterMap identity
            [ Maybe.map ((|>) data) printer.signature
            , Just ""
            , Just <| printer.comment data
            ]


unionToSignature : Union -> String
unionToSignature union =
    let
        writeVariant isFirst ( tvar, tipe ) =
            let
                prefix =
                    if isFirst then
                        "    = "

                    else
                        "    | "
            in
            prefix ++ tvar ++ String.join " " (List.map printType tipe)
    in
    String.join "\n"
        << List.concat
    <|
        [ [ "```elm"
          , "type " ++ union.name ++ " " ++ String.join " " union.args
          ]
        , case union.tags of
            [] ->
                []

            x :: xs ->
                writeVariant True x
                    :: List.map (writeVariant False) xs
        , [ "```" ]
        ]


printType : Type.Type -> String
printType tipe =
    case tipe of
        Type.Var name ->
            name

        Type.Lambda t1 t2 ->
            printType t1 ++ " -> " ++ printType t2

        Type.Tuple args ->
            "( " ++ String.join ", " (List.map printType args) ++ " )"

        Type.Type tname args ->
            tname ++ " " ++ String.join " " (List.map printType args)

        Type.Record fields Nothing ->
            let
                writeField ( fld, t0 ) =
                    fld ++ " : " ++ printType t0
            in
            if List.length fields < 4 then
                "{ " ++ String.join "    \n," (List.map writeField fields) ++ "    \n}"

            else
                ""

        _ ->
            "a"
