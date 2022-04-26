module Renderer.Docs exposing
    ( printTopLevelMarkdown
    , printUnion
    , printAlias
    , printValue
    )

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


printTopLevelMarkdown : String -> String
printTopLevelMarkdown md =
    String.join "\n"
        [ "----"
        , md
        ]


printUnion : Docs.Union -> String
printUnion union =
    union
        |> fromSection
            { title = "_type_ " ++ union.name
            , prelude = Nothing
            , body = prettyUnion
            , comment = union.comment
            }


printAlias : Docs.Alias -> String
printAlias al =
    al
        |> fromSection
            { title = "_type alias_ " ++ al.name
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
    [ Just <| "# " ++ title
    , prelude
    , Just <| defaultPrinter body source
    , Just comment
    ]
        |> List.filterMap identity
        |> String.join "\n"
