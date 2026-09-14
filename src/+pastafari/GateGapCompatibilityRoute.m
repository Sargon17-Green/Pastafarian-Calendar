classdef GateGapCompatibilityRoute
    % Produkcyjna trasa odstępu bramy po PATCH 15.
    %
    % Najpierw wykonuje historyczne positive-only question i zachowuje
    % jego mirrored day/gap jako bliznę. Publikowana ścieżka pyta dokładnie
    % Foundation+signedStep.
    methods (Static)
        function [ctx, gap] = call(ctx, signedStep)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(signedStep);

            step = pastafari.BigInt.coerce(signedStep);
            if step == pastafari.BigInt(0)
                error('Pastafari:Gates:ZeroStep', ...
                    'Pytanie o odstęp bramy wymaga kroku różnego od zera.');
            end

            % Surowa historyczna blizna Discovery 15.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_15_POSITIVE_ONLY_GATE_QUESTION';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery15.positiveOnlyGateQuestion.calls');

            [rawGap, rawQuestionDay] = ...
                pastafari.LegacyPositiveOnlyGateQuestion.ask(step);

            % PATCH 15: znak signedStep jest częścią pytania semantycznego.
            ctx.phase = 'PATCH_15';
            ctx.subPhase = 15;
            ctx.mode = 'SIGNED_GATE_QUESTION_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_15_SIGNED_GATE_QUESTION';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch15.signedGateQuestion.calls');

            [gap, signedQuestionDay] = ...
                pastafari.SignedGateQuestionPatch.ask(step);

            ctx.gateSignedStep = step;
            ctx.legacyPositiveOnlyGateQuestionDay = rawQuestionDay;
            ctx.legacyPositiveOnlyGateGap = rawGap;
            ctx.gateQuestionDayCandidate = signedQuestionDay;
            ctx.gateGapCandidate = gap;
            ctx.diagnostics{end + 1} = ...
                ['PATCH 15 zachowuje mirrored positive-only scar, ', ...
                 'ale publikuje pytanie Foundation+signedStep.'];
        end
    end
end
