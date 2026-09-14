classdef SmallPickCompatibilityRoute
    % Produkcyjna trasa krótkiego wyboru po PATCH 13.
    %
    % Najpierw wykonuje dokładnie surową ścieżkę Discovery 13:
    % biasedLegacyPick na pierwszym x bez rejection.
    % Publikowana ścieżka przesuwa się po tym samym answer ring aż
    % x<=limit i dopiero wtedy wywołuje ten sam LegacyBiasedPick.
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
                    ['Krótka ścieżka PATCH 13 wymaga N nie większego ', ...
                     'od rozmiaru answer ring.']);
            end

            % Surowa historyczna blizna Discovery 13.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_13_BIASED_LEGACY_PICK_MODULO';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery13.biasedLegacyPick.calls');

            rawX = pastafari.AnswerRingStreamFactory.answerAt( ...
                stream, pastafari.BigInt(0));
            rawRank = pastafari.LegacyBiasedPick.pick(rawX, N);

            ctx.answerRingFirst = pastafari.BigInt.coerce(stream.first);
            ctx.answerRingDirectionStep = stream.directionStep;
            ctx.legacyBiasedPickInput = rawX;
            ctx.legacyBiasedPickSize = N;
            ctx.legacyBiasedPickRank = rawRank;

            % PATCH 13: rejection przed semantic call do legacy pickera.
            ctx.phase = 'PATCH_13';
            ctx.subPhase = 13;
            ctx.mode = 'REJECTION_ON_ANSWER_RING_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_13_REJECTION_ON_ANSWER_RING';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch13.rejectionOnAnswerRing.calls');

            [rank, acceptedX, offset, acceptanceLimit] = ...
                pastafari.AnswerRingRejectionPatch.apply(stream, N);

            ctx.smallPickCandidate = rank;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 13: limit=%s, acceptedX=%s, offset=%s; ', ...
                 'LegacyBiasedPick został wywołany semantycznie dopiero ', ...
                 'po zaakceptowaniu odpowiedzi na tym samym answer ring.'], ...
                char(acceptanceLimit), char(acceptedX), char(offset));
        end
    end
end
