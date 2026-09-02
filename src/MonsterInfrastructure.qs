namespace Pastafari.MonsterInfrastructure {
    struct BaseMonsterContext {
        CalculationDay : BigInt,
        TargetDay : BigInt,
        Phase : Int,
        SubPhase : Int,
        StatusCode : Int,
        RetryBudget : Int,
        ValidationFailures : Int,
        MetricTicks : Int,
        LogTicks : Int,
        CommitToken : Int,
    }

    struct BaseDispatchResult {
        Context : BaseMonsterContext,
        Accepted : Bool,
    }

    function NewBaseMonsterContext(calculationDay : BigInt, targetDay : BigInt) : BaseMonsterContext {
        return BaseMonsterContext(
            calculationDay,
            targetDay,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        );
    }

    function BaseValidateContext(ctx : BaseMonsterContext) : BaseMonsterContext {
        if ctx.RetryBudget != 0 {
            fail "Bootstrap 段階では再試行機構を有効化できません。";
        }
        if ctx.Phase < 0 or ctx.SubPhase < 0 {
            fail "Bootstrap コンテキストの状態が不正です。";
        }
        return ctx;
    }

    function BaseMetricsTick(ctx : BaseMonsterContext) : BaseMonsterContext {
        return new BaseMonsterContext { ...ctx, MetricTicks = ctx.MetricTicks + 1 };
    }

    function BaseLogTick(ctx : BaseMonsterContext) : BaseMonsterContext {
        return new BaseMonsterContext { ...ctx, LogTicks = ctx.LogTicks + 1 };
    }

    function BaseDispatcher(ctx : BaseMonsterContext) : BaseDispatchResult {
        let checked = BaseValidateContext(ctx);
        let withMetric = BaseMetricsTick(checked);
        let withLog = BaseLogTick(withMetric);
        let committed = new BaseMonsterContext {
            ...withLog,
            Phase = 1,
            StatusCode = 1,
            CommitToken = withLog.CommitToken + 1
        };
        return BaseDispatchResult(committed, true);
    }
}
