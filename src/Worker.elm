port module Worker exposing (main)

import Elm.Docs as Docs exposing (Block(..))
import Elm.Package as Pkg
import Json.Decode as JD exposing (Value)
import Json.Encode as JE
import Platform
import Renderer.Docs as Render


main : Program Value Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }



-- PORTS


port docsFinder : String -> Cmd msg


port docsWriter : Value -> Cmd msg


port abort : ExitCode -> Cmd msg


port moduleLoader : (Value -> msg) -> Sub msg



-- MODEL


type Model
    = Working Config
    | Fatal


type alias Config =
    { specifier : String
    }


configDecoder : JD.Decoder Config
configDecoder =
    JD.map Config <|
        JD.field "specifier" JD.string


type alias Bundle =
    { fqn : String
    , slug : String
    , markdown : String
    }


encodeBundles : List Bundle -> Value
encodeBundles =
    JE.list
        (\bundle ->
            JE.object
                [ ( "fqn", JE.string bundle.fqn )
                , ( "slug", JE.string bundle.slug )
                , ( "markdown", JE.string bundle.markdown )
                ]
        )


bundleModule : Docs.Module -> Bundle
bundleModule mod =
    { fqn = mod.name
    , slug = toSlug mod.name
    , markdown = writeMarkdown mod
    }


writeMarkdown : Docs.Module -> String
writeMarkdown mod =
    Docs.toBlocks mod
        |> List.filterMap
            (\block ->
                case block of
                    MarkdownBlock str ->
                        Just str

                    UnionBlock u ->
                        Just (Render.printUnion u)

                    AliasBlock al ->
                        Just (Render.printAlias al)

                    ValueBlock v ->
                        Just (Render.printValue v)

                    _ ->
                        Nothing
            )
        |> String.join "\n"


init : Value -> ( Model, Cmd Msg )
init json =
    case JD.decodeValue configDecoder json of
        Ok config ->
            case Pkg.fromString config.specifier of
                Just _ ->
                    ( Working config
                    , docsFinder config.specifier
                    )

                Nothing ->
                    ( Fatal
                    , abort
                        { code = 1
                        , message = "Invalid package name"
                        }
                    )

        Err _ ->
            ( Fatal
            , abort
                { code = 2
                , message = "Failed to decode flags"
                }
            )


type Msg
    = NoOp
    | GotModules Value


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Fatal ->
            ( model
            , abort
                { code = 3
                , message = "Unexpected error"
                }
            )

        Working _ ->
            case msg of
                GotModules json ->
                    case JD.decodeValue (JD.list Docs.decoder) json of
                        Ok docs ->
                            ( model
                            , docsWriter <| encodeBundles <| List.map bundleModule docs
                            )

                        Err _ ->
                            ( Fatal
                            , abort
                                { code = 4
                                , message = "Invalid `docs.json` data"
                                }
                            )

                NoOp ->
                    ( model, Cmd.none )


type alias ExitCode =
    { code : Int
    , message : String
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Working _ ->
            moduleLoader GotModules

        Fatal ->
            Sub.none



-- HELPERS


toSlug : String -> String
toSlug moduleName =
    moduleName
        |> String.split "."
        |> List.map String.toLower
        |> String.join "-"
