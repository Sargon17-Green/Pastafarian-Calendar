module Pastafari.Spaghetti exposing
    ( BootstrapResult
    , SpaghettiError(..)
    , calendarDateSpaghetti
    )

import Pastafari.ExactInt exposing (BigInt)
import Pastafari.MonsterBase as MonsterBase


type SpaghettiError
    = BootstrapOnly
    | BaseValidationFailed String


type alias BootstrapResult =
    { calculationDay : BigInt
    , targetDay : BigInt
    , traceDepth : Int
    }


calendarDateSpaghetti : BigInt -> BigInt -> Result SpaghettiError BootstrapResult
calendarDateSpaghetti calculationDay targetDay =
    let
        context0 =
            MonsterBase.newContext calculationDay targetDay

        context1 =
            MonsterBase.dispatch MonsterBase.neutralDispatcher context0
                |> MonsterBase.recordMetric "bootstrap.dispatch"
    in
    case MonsterBase.validateBaseContext context1 of
        MonsterBase.Invalid _ message ->
            Err (BaseValidationFailed message)

        MonsterBase.Valid context2 ->
            if context2.phase == MonsterBase.BootstrapReady then
                Err BootstrapOnly

            else
                Err BootstrapOnly
