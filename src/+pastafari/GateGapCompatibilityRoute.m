classdef GateGapCompatibilityRoute
    % Produkcyjna trasa Discovery 15.
    %
    % Publikuje jeszcze historyczne pytanie positive-only:
    % signedStep=-n jest mapowany na Foundation+n zamiast Foundation-n.
    methods (Static)
        function [ctx, gap] = call(ctx, signedStep)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(signedStep);

            step = pastafari.BigInt.coerce(signedStep);
            if step == pastafari.BigInt(0)
                error('Pastafari:Gates:ZeroStep', ...
                    'Pytanie o odstęp bramy wymaga kroku różnego od zera.');
            end

            ctx.phase = 'DISCOVERY_15';
            ctx.subPhase = 15;
            ctx.mode = 'POSITIVE_ONLY_GATE_QUESTION';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_15_POSITIVE_ONLY_GATE_QUESTION';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery15.positiveOnlyGateQuestion.calls');

            [rawGap, rawQuestionDay] = ...
                pastafari.LegacyPositiveOnlyGateQuestion.ask(step);

            ctx.gateSignedStep = step;
            ctx.legacyPositiveOnlyGateQuestionDay = rawQuestionDay;
            ctx.legacyPositiveOnlyGateGap = rawGap;
            ctx.gateQuestionDayCandidate = rawQuestionDay;
            ctx.gateGapCandidate = rawGap;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 15 ignoruje znak signedStep i dla bramy ujemnej ', ...
                 'zadaje lustrzane pytanie Foundation+abs(step).'];

            gap = rawGap;
        end
    end
end
