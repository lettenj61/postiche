module Example exposing (main)

import Browser exposing (Document)
import Elm.Docs as Docs exposing (Block(..), Module)
import Html
import Html.Attributes as Attrs
import Http
import Json.Decode as Decode
import Markdown
import Renderer.Docs as Render


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type Model
    = Loading
    | Code (List Module)
    | NoData Http.Error


init : () -> ( Model, Cmd Msg )
init _ =
    ( Loading
    , fetchElmBytesDoc
    )


decoder : Decode.Decoder (List Module)
decoder =
    Decode.list Docs.decoder



-- UPDATE


type Msg
    = Fetch (Result Http.Error (List Module))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model of
        Loading ->
            case msg of
                Fetch result ->
                    case result of
                        Ok docs ->
                            ( Code docs, Cmd.none )

                        Err err ->
                            ( NoData err, Cmd.none )

        _ ->
            ( model, Cmd.none )


fetchElmBytesDoc : Cmd Msg
fetchElmBytesDoc =
    Http.get
        { url = "./elm-bytes-docs.json"
        , expect =
            Http.expectJson
                Fetch
                decoder
        }



-- VIEW


view : Model -> Document msg
view model =
    let
        sections docs =
            List.concatMap printMarkdowns docs

        content =
            case model of
                Code docs ->
                    Html.div
                        [ Attrs.class "markdown-section"
                        ]
                        [ Markdown.toHtml [] <|
                            String.join "\n\n" (sections docs)
                        ]

                NoData err ->
                    Html.h3
                        []
                        [ fromHttpError err ]

                Loading ->
                    Html.h3
                        []
                        [ Html.text "Loading..." ]
    in
    { title = "Elm Postiche Example"
    , body =
        [ Html.node "link"
            [ Attrs.rel "stylesheet"
            , Attrs.href "https://unpkg.com/docsify@4.12.2/themes/vue.css"
            ]
            []
        , Html.node "style" []
            [ (String.trim >> Html.text)
                """
                body:not(.ready) {
                    overflow: initial;
                }
                """
            ]
        , content
        ]
    }


fromHttpError : Http.Error -> Html.Html msg
fromHttpError err =
    case err of
        Http.BadBody cause ->
            Html.text cause

        _ ->
            Html.text "Something wrong."


printMarkdowns : Module -> List String
printMarkdowns mod =
    let
        markdownBlocks =
            Docs.toBlocks mod
                |> List.filterMap
                    (\block ->
                        case block of
                            MarkdownBlock str ->
                                Just <| "- - - -\n\n" ++ str

                            UnionBlock u ->
                                Just (Render.printUnion u)

                            AliasBlock al ->
                                Just (Render.printAlias al)

                            ValueBlock v ->
                                Just (Render.printValue v)

                            _ ->
                                Nothing
                    )
    in
    markdownBlocks
