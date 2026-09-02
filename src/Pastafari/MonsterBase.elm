module Pastafari.MonsterBase exposing
    ( BaseContext
    , BaseDispatcher
    , BaseStatus(..)
    , Phase(..)
    , ValidationResult(..)
    , dispatch
    , newContext
    , neutralDispatcher
    , recordMetric
    , validateBaseContext
    )

import Dict exposing (Dict)
import Pastafari.ExactInt exposing (BigInt)


type Phase
    = BootstrapEntry
    | BootstrapValidation
    | BootstrapReady


type BaseStatus
    = New
    | Validating
    | Ready
    | Failed


type alias BaseContext =
    { calculationDay : BigInt
    , targetDay : BigInt
    , phase : Phase
    , status : BaseStatus
    , branchTrace : List String
    , metrics : Dict String Int
    , diagnostics : List String
    }


type alias BaseDispatcher =
    { next : Phase -> Phase
    }


type ValidationResult
    = Valid BaseContext
    | Invalid BaseContext String


newContext : BigInt -> BigInt -> BaseContext
newContext calculationDay targetDay =
    { calculationDay = calculationDay
    , targetDay = targetDay
    , phase = BootstrapEntry
    , status = New
    , branchTrace = [ "BOOTSTRAP_ENTRY" ]
    , metrics = Dict.empty
    , diagnostics = []
    }


neutralDispatcher : BaseDispatcher
neutralDispatcher =
    { next =
        \phase ->
            case phase of
                BootstrapEntry ->
                    BootstrapValidation

                BootstrapValidation ->
                    BootstrapReady

                BootstrapReady ->
                    BootstrapReady
    }


dispatch : BaseDispatcher -> BaseContext -> BaseContext
dispatch dispatcher context =
    let
        nextPhase =
            dispatcher.next context.phase
    in
    { context
        | phase = nextPhase
        , branchTrace = context.branchTrace ++ [ phaseToken nextPhase ]
    }


phaseToken : Phase -> String
phaseToken phase =
    case phase of
        BootstrapEntry ->
            "BOOTSTRAP_ENTRY"

        BootstrapValidation ->
            "BOOTSTRAP_VALIDATION"

        BootstrapReady ->
            "BOOTSTRAP_READY"


recordMetric : String -> BaseContext -> BaseContext
recordMetric key context =
    let
        nextValue =
            Dict.get key context.metrics
                |> Maybe.withDefault 0
                |> (+) 1
    in
    { context | metrics = Dict.insert key nextValue context.metrics }


validateBaseContext : BaseContext -> ValidationResult
validateBaseContext context =
    if List.isEmpty context.branchTrace then
        Invalid { context | status = Failed } "Grunnsamhengið vantar framkvæmdarslóð."

    else
        Valid { context | status = Ready }
