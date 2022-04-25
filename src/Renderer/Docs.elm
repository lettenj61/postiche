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
    union
        |> fromSection
            { title = union.name
            , prelude = Nothing
            , body = prettyUnion
            , comment = union.comment
            }


printAlias : Docs.Alias -> String
printAlias al =
    al
        |> fromSection
            { title = al.name
            , prelude = Nothing
            , body = prettyAlias
            , comment = al.comment
            }


printValue : Docs.Value -> String
printValue value =
    value
        |> fromSection
            { title = value.name |> toCode
            , prelude = Nothing
            , body = prettyValue
            , comment = value.comment
            }



-- PRETTY PRINTERS


prettyUnion : Docs.Union -> Element
prettyUnion =
    ElmPretty.prettyCustomType << Transform.transformUnion


prettyAlias : Docs.Alias -> Element
prettyAlias =
    ElmPretty.prettyTypeAlias << Transform.transformAlias


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


toCode : String -> String
toCode elem =
    "`" ++ elem ++ "`"


wrapCodeFences : String -> String
wrapCodeFences body =
    String.join "\n" <|
        [ "```elm"
        , body
        , "```"
        ]


fromSection : Section a -> a -> String
fromSection { title, prelude, body, comment } source =
    [ Just <| "### " ++ title
    , prelude
    , Just <| defaultPrinter body source
    , Just comment
    ]
        |> List.filterMap identity
        |> String.join "\n"
