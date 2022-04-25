module Renderer.Docs exposing (..)

{-| Print tree as markdown
-}

import Elm.Docs as Docs
import Elm.Pretty as ElmPretty
import Pretty
import Renderer.Transform as Transform


type alias Element =
    Pretty.Doc ElmPretty.Tag


type alias Section a =
    { title : String
    , prelude : Maybe String
    , body : a -> Element
    , comment : String
    }



-- MARKDOWN


printUnion : Docs.Union -> String
printUnion union =
    fromSection
        union
        { title = union.name
        , prelude = Nothing
        , body = prettyUnion
        , comment = union.comment
        }


printValue : Docs.Value -> String
printValue value =
    fromSection
        value
        { title = value.name
        , prelude = Nothing
        , body = prettyValue
        , comment = value.comment
        }



-- PRETTY PRINTERS


prettyUnion : Docs.Union -> Element
prettyUnion =
    ElmPretty.prettyCustomType << Transform.transformUnion2


prettyValue : Docs.Value -> Element
prettyValue =
    ElmPretty.prettySignature << Transform.transformValue



-- PRINTER CONFIGURATIONS


defaultPrinter : (s -> Pretty.Doc t) -> s -> String
defaultPrinter printer tree =
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


fromSection : a -> Section a -> String
fromSection source { title, prelude, body, comment } =
    [ Just <| "### " ++ title
    , prelude
    , Just <| defaultPrinter body source
    , Just comment
    ]
        |> List.filterMap identity
        |> String.join "\n"
