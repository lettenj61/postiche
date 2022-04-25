module Worker exposing (main)

import Json.Decode as JD exposing (Value)
import Platform


main : Program Value Model Msg
main =
    Platform.worker
        { init = init
        , update =
            \_ model -> ( model, Cmd.none )
        , subscriptions = always Sub.none
        }


type Model
    = Model


init : Value -> ( Model, Cmd Msg )
init _ =
    ( Model, Cmd.none )


type Msg
    = NoOp
