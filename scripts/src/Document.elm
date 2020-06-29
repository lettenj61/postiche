module Document exposing
    ( Module
    , Union
    , Val
    , decoder
    , makeContentMap
    )

import Json.Decode as Decode exposing (Decoder)



-- TYPES


type alias Val =
    { comment : String
    , name : String
    , type_ : String
    }


type alias Alias =
    { comment : String
    , name : String
    , args : List String
    , type_ : String
    }


type alias Union =
    { comment : String
    , name : String
    , args : List String
    , cases : List ( String, List String )
    }


type alias Module =
    { comment : String
    , name : String
    , unions : List Union
    , aliases : List Alias
    , values : List Val
    , binops : List Val
    }



-- WRITING MARKDOWN


makeContentMap : List Module -> List ( String, String )
makeContentMap pkgs =
    makeContentMapHelp pkgs []


makeContentMapHelp : List Module -> List ( String, String ) -> List ( String, String )
makeContentMapHelp pkgs collctedDocs =
    let
        writePkg : Module -> String
        writePkg pkg =
            String.join "\n"
                [ pkg.name
                , String.repeat (String.length pkg.name) "="
                , pkg.comment
                    |> String.lines
                    |> List.map (\comm -> resolveRef comm pkg)
                    |> String.join "\n"
                ]
    in
    case pkgs of
        [] ->
            collctedDocs

        pkg :: rest ->
            makeContentMapHelp
                rest
                (( pkg.name ++ ".md", writePkg pkg ) :: collctedDocs)


resolveRef : String -> Module -> String
resolveRef comment pkg =
    if String.startsWith "@docs" comment then
        let
            resolveError ref =
                "ERROR IN WRITING MARKDOWN: could not resolve reference: " ++ ref

            refs =
                comment
                    |> String.dropLeft 5
                    |> String.split ","
                    |> List.map String.trim

            blocks =
                refs
                    |> List.map
                        (\ref ->
                            case lookup ref pkg of
                                Just doc ->
                                    doc

                                Nothing ->
                                    resolveError ref
                        )
                    |> String.join "\n"
        in
        blocks

    else if String.left 1 comment == "#" then
        "#" ++ comment ++ "\n"

    else
        comment


lookup : String -> Module -> Maybe String
lookup symbol pkg =
    lookupBy .unions .name symbol pkg
        |> Maybe.map writeType
        |> recoverWith
            (lookupBy .aliases .name symbol pkg
                |> Maybe.map writeAlias
            )
        |> recoverWith
            (lookupBy .values .name symbol pkg
                |> Maybe.map writeMember
            )
        |> recoverWith
            (lookupBy .binops wrapOperator symbol pkg
                |> Maybe.map writeMember
            )


lookupBy : (Module -> List a) -> (a -> String) -> String -> Module -> Maybe a
lookupBy whatField whatProp symbol pkg =
    whatField pkg
        |> List.filter (\prop -> symbol == whatProp prop)
        |> List.head


writeType : Union -> String
writeType unn =
    let
        declOp index =
            if index == 0 then
                "="

            else
                "|"

        formatter { name, args, cases } =
            List.concat
                [ [ "type " ++ name ++ " " ++ String.join " " args ]
                , List.indexedMap
                    (\index ( branch, innerParams ) ->
                        "    " ++ declOp index ++ " " ++ branch ++ " " ++ String.join " " innerParams
                    )
                    cases
                ]
    in
    String.join "\n"
        [ "#### `type " ++ unn.name ++ "`"
        , toCodeBlock <| formatter unn
        , unn.comment
        ]


writeAlias : Alias -> String
writeAlias al =
    let
        formatter { name, args, type_ } =
            [ "type alias " ++ name ++ " " ++ String.join " " args
            , "    = " ++ type_
            ]
    in
    String.join "\n"
        [ toCodeBlock <| formatter al
        , al.comment
        ]


writeMember : Val -> String
writeMember val =
    let
        formatter { name, type_ } =
            "#### `" ++ name ++ " : " ++ type_ ++ "`"

        ( snippet, description ) =
            deconstructComments val.comment
    in
    String.join "\n"
        [ formatter val
        , ""
        , String.join "\n" description
        , if List.length snippet > 0 then
            toCodeBlock snippet

          else
            ""
        ]


deconstructComments : String -> ( List String, List String )
deconstructComments comment =
    comment
        |> String.lines
        |> List.partition
            (\line -> String.left 4 line == "    ")


toCodeBlock : List String -> String
toCodeBlock lines =
    "```elm\n" ++ String.join "\n" lines ++ "\n```\n"


recoverWith : Maybe a -> Maybe a -> Maybe a
recoverWith attempt fallback =
    case attempt of
        Just _ ->
            attempt

        Nothing ->
            fallback


wrapOperator : Val -> String
wrapOperator { name } =
    "(" ++ name ++ ")"


-- DECODERS


stringProperty : String -> Decoder String
stringProperty fieldName =
    Decode.field fieldName Decode.string


valueMemberDecoder : Decoder Val
valueMemberDecoder =
    Decode.map3 Val
        (stringProperty "comment")
        (stringProperty "name")
        (stringProperty "type")


aliasDecoder : Decoder Alias
aliasDecoder =
    Decode.map4 Alias
        (stringProperty "comment")
        (stringProperty "name")
        (Decode.field "args" (Decode.list Decode.string))
        (stringProperty "type")


unionMemberDecoder : Decoder Union
unionMemberDecoder =
    let
        caseDecoder =
            Decode.map2 Tuple.pair
                (Decode.index 0 Decode.string)
                (Decode.index 1 <| Decode.list Decode.string)
    in
    Decode.map4 Union
        (stringProperty "comment")
        (stringProperty "name")
        (Decode.field "args" (Decode.list Decode.string))
        (Decode.field
            "cases"
            (Decode.list caseDecoder)
        )


decoder : Decoder Module
decoder =
    Decode.map6 Module
        (stringProperty "comment")
        (stringProperty "name")
        (Decode.field "unions" (Decode.list unionMemberDecoder))
        (Decode.field "aliases" (Decode.list aliasDecoder))
        (Decode.field "values" (Decode.list valueMemberDecoder))
        (Decode.field "binops" (Decode.list valueMemberDecoder))
