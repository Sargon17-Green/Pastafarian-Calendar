classdef SmallPickCompatibilityRoute
    % Produkcyjna trasa Discovery 13.
    %
    % Legacy bierze pierwszą odpowiedź answer ring i natychmiast wywołuje
    % biasedLegacyPick. Nie ma jeszcze rejection ani acceptance limit.
    methods (Static)
        function [ctx, rank] = call(ctx, stream, N)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(N);

            N = pastafari.BigInt.coerce(N);
            M = pastafari.BigInt( ...
                '170141183460469231731687303715884105727');
            if N < pastafari.BigInt(1)
                error('Pastafari:Selection:Size', ...
                    'Liczba dróg wyboru musi być dodatnia.');
            end
            if N > M
                error('Pastafari:Selection:LegacyShortAssumption', ...
                    ['Historyczna krótka ścieżka Discovery 13 zakłada ', ...
                     'N nie większe od rozmiaru answer ring.']);
            end

            ctx.phase = 'DISCOVERY_13';
            ctx.subPhase = 13;
            ctx.mode = 'BIASED_LEGACY_PICK_MODULO';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_13_BIASED_LEGACY_PICK_MODULO';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery13.biasedLegacyPick.calls');

            x = pastafari.AnswerRingStreamFactory.answerAt( ...
                stream, pastafari.BigInt(0));
            rawRank = pastafari.LegacyBiasedPick.pick(x, N);

            ctx.answerRingFirst = pastafari.BigInt.coerce(stream.first);
            ctx.answerRingDirectionStep = stream.directionStep;
            ctx.legacyBiasedPickInput = x;
            ctx.legacyBiasedPickSize = N;
            ctx.legacyBiasedPickRank = rawRank;
            ctx.smallPickCandidate = rawRank;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 13 wywołuje biasedLegacyPick na pierwszej ', ...
                 'odpowiedzi pierścienia bez rejection.'];

            rank = rawRank;
        end
    end
end
