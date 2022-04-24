module Renderer.Markdown exposing (..)

import Elm.Docs as Docs exposing (Alias, Union)
import Elm.Type as Type


printUnion : Union -> String
printUnion union =
    let
        variants =
            union.tags
                |> List.map Tuple.first
                |> List.map ((++) "    | ")

        signature =
            "type " ++ union.name ++ " " ++ String.join " " union.args
    in
    fence <|
        signature
            :: variants


printAlias : Alias -> String
printAlias al =
    backtick <|
        String.join " "
            [ "type alias"
            , al.name
            , String.join " " al.args
            ]


printType : Type.Type -> String
printType tipe =
    case tipe of
        Type.Var var ->
            backtick var

        Type.Lambda t1 t2 ->
            printType t1 ++ " -> " ++ printType t2

        _ ->
            ""



-- HELPERS


backtick : String -> String
backtick elem =
    "`" ++ elem ++ "`"


fence : List String -> String
fence codes =
    (String.join "\n" <|
        "```elm"
            :: codes
    )
        ++ "```"
