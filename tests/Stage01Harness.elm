port module Stage01Harness exposing (main)

import Platform
import Stage01Checks


port report : String -> Cmd msg


type Msg
    = NoOp


type alias Model =
    ()


init : () -> ( Model, Cmd Msg )
init _ =
    ( (), report Stage01Checks.summary )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
