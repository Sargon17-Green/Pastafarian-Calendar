classdef CutletPartitionCompatibilityRoute
    % Produkcyjna trasa Discovery 21.
    %
    % internalGateOffset jest obserwowalny, ale legacy family/selection
    % celowo go ignorują. Stage 42 publikuje surową kompozycję legacy.
    methods (Static)
        function [ctx, partition] = call( ...
                ctx, stream, gapCount, cutletCount, internalGateOffset)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(gapCount);
            pastafari.ValidationManager.requireExactIntegerInput(cutletCount);

            G = pastafari.BigInt.coerce(gapCount);
            K = pastafari.BigInt.coerce(cutletCount);

            if G < pastafari.BigInt(1) || K < pastafari.BigInt(1)
                error('Pastafari:Cutlets:PartitionShape', ...
                    'gapCount i cutletCount muszą być dodatnie.');
            end

            if isempty(internalGateOffset)
                offset = [];
            else
                pastafari.ValidationManager.requireExactIntegerInput( ...
                    internalGateOffset);
                offset = pastafari.BigInt.coerce(internalGateOffset);

                if offset <= pastafari.BigInt(0) || offset >= G
                    error('Pastafari:Cutlets:InternalGateOffset', ...
                        ['Wewnętrzny gate offset musi należeć do ', ...
                         'przedziału 1..gapCount-1.']);
                end
            end

            [ctx, rank, rawPartition, familyCount, descriptor] = ...
                pastafari.LegacyCutletPartitionAdapter.callWithRing( ...
                    ctx, stream, G, K);

            ctx.phase = 'DISCOVERY_21';
            ctx.subPhase = 21;
            ctx.mode = 'UNFILTERED_CUTLET_PARTITIONS';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_21_UNFILTERED_CUTLET_PARTITIONS';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, ...
                'discovery21.unfilteredCutletPartitions.calls');

            ctx.cutletGapCount = G;
            ctx.cutletCountCandidate = K;
            ctx.cutletInternalGateOffset = offset;
            ctx.legacyPositiveCompositions = descriptor;
            ctx.legacyCutletPartitionFamilyCount = familyCount;
            ctx.legacyCutletPartitionRank = rank;
            ctx.legacyCutletPartition = rawPartition;
            ctx.cutletPartitionCandidate = rawPartition;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 21 publikuje wszystkie dodatnie kompozycje; ', ...
                 'internalGateOffset jest zapisany, ale nie filtruje rodziny.'];

            partition = rawPartition;
        end
    end
end
