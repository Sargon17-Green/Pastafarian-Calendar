classdef CutletNameCompatibilityRoute
    % Produkcyjna trasa Discovery 22.
    %
    % Używa bowl 5 / seal 22 z authoritative structure sauce, ale
    % historyczna rodzina nadal dopuszcza repeated canonical indices.
    methods (Static)
        function [ctx, nameIndices] = call( ...
                ctx, structureSauce, cutletCount)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(cutletCount);

            count = pastafari.BigInt.coerce(cutletCount);
            if count < pastafari.BigInt(1) || ...
                    count > pastafari.BigInt(17)
                error('Pastafari:Names:CutletCount', ...
                    'cutletCount musi należeć do 1..17.');
            end

            pastafari.CutletNameCompatibilityRoute.requireSauce( ...
                structureSauce);

            nextBowlId = pastafari.LatchedSuccessorPatch.apply( ...
                structureSauce.orderAt46Latch, 5);
            stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
                structureSauce.bowls, 5, nextBowlId, 22);

            [ctx, rank, rawIndices, familyCount, descriptor] = ...
                pastafari.LegacyRepeatedNameGenerator.callWithRing( ...
                    ctx, stream, pastafari.BigInt(17), count); %#ok<ASGLU>

            ctx.phase = 'DISCOVERY_22';
            ctx.subPhase = 22;
            ctx.mode = 'REPEATED_CUTLET_NAMES';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_22_REPEATED_NAMES';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery22.repeatedNames.calls');

            ctx.cutletNameStreamFirst = stream.first;
            ctx.cutletNameStreamDirectionStep = stream.directionStep;
            ctx.legacyCutletNameFamilyCount = familyCount;
            ctx.legacyCutletNameRank = rank;
            ctx.legacyNameCandidateIndices = rawIndices;
            ctx.cutletNameIndicesCandidate = rawIndices;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['Discovery 22 używa family=%s count=%s rank=%s; ', ...
                 'powtórzenia canonicalIndex są nadal legalne.'], ...
                descriptor.familyName, char(familyCount), char(rank));

            nameIndices = rawIndices;
        end
    end

    methods (Static, Access = private)
        function requireSauce(sauce)
            if ~isstruct(sauce) || ...
                    ~isfield(sauce, 'bowls') || ...
                    ~isfield(sauce, 'orderAt46Latch')
                error('Pastafari:Names:StructureSauceShape', ...
                    'Cutlet names wymagają bowls i orderAt46Latch.');
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
