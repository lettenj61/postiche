port module Reader exposing (main)

import Document exposing (Module)
import Json.Decode as Decode exposing (Value)
import Platform


port elmReady : Descriptor -> Cmd msg


port newContentMap : List ( String, String ) -> Cmd msg


port terminate : { code : Int, errors : Maybe String } -> Cmd msg


port resolvedPackage : (Value -> msg) -> Sub msg


port allDone : (() -> msg) -> Sub msg


main : Program String Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }



-- INIT


type Model
    = PackageRequest Descriptor
    | ResolvedDoc (List Module)
    | InvalidArgs


type alias Descriptor =
    { author : String
    , project : String
    , version : String
    }


init : String -> ( Model, Cmd msg )
init args =
    case parseArgs args of
        Just props ->
            ( PackageRequest props, elmReady props )

        Nothing ->
            ( InvalidArgs
            , terminate
                { code = 9
                , errors =
                    Just <| "invalid argument: expected <author:project:version>, got `" ++ args ++ "`"
                }
            )


parseArgs : String -> Maybe Descriptor
parseArgs args =
    case String.split ":" args of
        author :: project :: version :: [] ->
            Just { author = author, project = project, version = version }

        _ ->
            Nothing



-- UPDATE


type Msg
    = NoOp
    | NewPackage Value
    | Quit
    | ExternalFailure


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NewPackage pkgs ->
            case Decode.decodeValue (Decode.list Document.decoder) pkgs of
                Ok docs ->
                    ( ResolvedDoc docs
                    , newContentMap <| Document.makeContentMap docs
                    )

                Err decodeError ->
                    ( model
                    , terminate
                        { code = 1
                        , errors = Just (Decode.errorToString decodeError)
                        }
                    )

        Quit ->
            ( model, terminate { exitState | code = 0 } )

        ExternalFailure ->
            ( model, terminate { code = 9, errors = Just "unknown error in JavaScript" } )


exitState : { code : Int, errors : Maybe String }
exitState =
    { code = 0
    , errors = Nothing
    }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        PackageRequest _ ->
            Sub.batch
                [ resolvedPackage NewPackage
                , allDone <| always ExternalFailure
                ]

        ResolvedDoc _ ->
            allDone <| always Quit

        _ ->
            allDone <| always ExternalFailure
