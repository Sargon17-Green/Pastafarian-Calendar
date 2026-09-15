classdef MonthNameCompatibilityRoute
    % PATCH 22: nazwy miesięcy korzystają z tego samego distinct-name detour.
    %
    % Master katalogu miesięcy ma 47 pozycji. Answer ring: bowl 5 / seal 33.
    % Raw repeated candidate jest nadal wykonywany i zachowywany jako scar.
    methods (Static)
        function [ctx, nameIndices] = call( ...
                ctx, structureSauce, monthCount)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(monthCount);

            count = pastafari.BigInt.coerce(monthCount);
            if count < pastafari.BigInt(1) || ...
                    count > pastafari.BigInt(47)
                error('Pastafari:Names:MonthCount', ...
                    'monthCount musi należeć do 1..47.');
            end

            pastafari.MonthNameCompatibilityRoute.requireSauce( ...
                structureSauce);

            nextBowlId = pastafari.LatchedSuccessorPatch.apply( ...
                structureSauce.orderAt46Latch, 5);
            stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
                structureSauce.bowls, 5, nextBowlId, 33);

            [ctx, rawRank, rawIndices, rawFamilyCount, rawDescriptor] = ...
                pastafari.LegacyRepeatedNameGenerator.callWithRing( ...
                    ctx, stream, pastafari.BigInt(47), count); %#ok<ASGLU>

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_22_REPEATED_NAMES';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery22.repeatedNames.calls');

            ctx.monthNameStreamFirst = stream.first;
            ctx.monthNameStreamDirectionStep = stream.directionStep;
            ctx.legacyMonthNameFamilyCount = rawFamilyCount;
            ctx.legacyMonthNameRank = rawRank;
            ctx.legacyMonthNameCandidateIndices = rawIndices;

            [ctx, distinctRank, semanticIndices, distinctCount, reusedLegacy] = ...
                pastafari.RepeatedNamePatchWrapper.callWithRing( ...
                    ctx, stream, pastafari.BigInt(47), count, rawIndices);

            ctx.phase = 'PATCH_22';
            ctx.subPhase = 22;
            ctx.mode = 'DISTINCT_MONTH_NAMES_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_22_DISTINCT_NAME_DETOUR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch22.distinctNameDetour.calls');

            ctx.distinctMonthNameFamilyCount = distinctCount;
            ctx.distinctMonthNameRank = distinctRank;
            ctx.monthNameIndicesCandidate = semanticIndices;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 22 months rawFamily=%s rawRank=%s ', ...
                 'distinctFamily=%s distinctRank=%s reusedLegacy=%d.'], ...
                char(rawFamilyCount), char(rawRank), ...
                char(distinctCount), char(distinctRank), reusedLegacy);

            nameIndices = semanticIndices;
        end
    end

    methods (Static, Access = private)
        function requireSauce(sauce)
            if ~isstruct(sauce) || ...
                    ~isfield(sauce, 'bowls') || ...
                    ~isfield(sauce, 'orderAt46Latch')
                error('Pastafari:Names:StructureSauceShape', ...
                    'Month names wymagają bowls i orderAt46Latch.');
            end

            if ~iscell(sauce.bowls) || numel(sauce.bowls) ~= 6
                error('Pastafari:Names:StructureSauceBowls', ...
                    'Structure sauce musi zawierać sześć bowls.');
            end

            order = sauce.orderAt46Latch;
            if ~(isnumeric(order) && isvector(order) && ...
                    numel(order) == 6 && ...
                    isequal(sort(order(:).'), 1:6))
                error('Pastafari:Names:StructureSauceOrder', ...
                    'orderAt46Latch musi być permutacją 1..6.');
            end
        end
    end
end
