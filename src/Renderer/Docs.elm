module Renderer.Docs exposing (..)

{-| Print tree as markdown
-}

import Elm.CodeGen as Gen
import Elm.Docs as Docs
import Elm.Pretty as ElmPretty
import Pretty
import Renderer.Transform as Transform


type alias Element =
    Pretty.Doc ElmPretty.Tag


printUnion : Docs.Union -> String
printUnion union =
    defaultPrettyPrint prettyUnion union
        |> appendComment union.comment



-- PRETTY PRINTERS


prettyUnion : Docs.Union -> Element
prettyUnion =
    ElmPretty.prettyDeclaration defaultWidth << Transform.transformUnion



-- PRINTER CONFIGURATIONS


defaultPrettyPrint : (s -> Pretty.Doc t) -> s -> String
defaultPrettyPrint printer tree =
    Pretty.pretty defaultWidth (printer tree)
        |> wrapCodeFences


defaultWidth : Int
defaultWidth =
    80



-- HELPERS


wrapCodeFences : String -> String
wrapCodeFences body =
    String.join "\n" <|
        [ "```elm"
        , body
        , "```"
        ]


appendComment : String -> String -> String
appendComment comment doc =
    doc ++ "\n" ++ comment
