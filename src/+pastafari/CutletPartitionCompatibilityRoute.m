classdef CutletPartitionCompatibilityRoute
    % Produkcyjna trasa podziałów kotletów po PATCH 21.
    %
    % Raw all-positive family/selection jest zawsze wykonywana jako pierwsza
    % i zachowywana jako blizna Discovery 21. Semantic path filtruje tylko
    % wtedy, gdy istnieje internal calculation-day gate.
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

            % Realny historyczny ghost: pełna rodzina i raw selection.
            [ctx, rawRank, rawPartition, rawFamilyCount, rawDescriptor] = ...
                pastafari.LegacyCutletPartitionAdapter.callWithRing( ...
                    ctx, stream, G, K);

            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_21_UNFILTERED_CUTLET_PARTITIONS';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, ...
                'discovery21.unfilteredCutletPartitions.calls');

            ctx.cutletGapCount = G;
            ctx.cutletCountCandidate = K;
            ctx.cutletInternalGateOffset = offset;
            ctx.legacyPositiveCompositions = rawDescriptor;
            ctx.legacyCutletPartitionFamilyCount = rawFamilyCount;
            ctx.legacyCutletPartitionRank = rawRank;
            ctx.legacyCutletPartition = rawPartition;

            [ctx, semanticRank, semanticPartition, semanticCount, ...
                semanticDescriptor, reusedLegacy] = ...
                pastafari.CutletPartitionGatePatchWrapper.callWithRing( ...
                    ctx, stream, G, K, offset, ...
                    rawRank, rawPartition, rawFamilyCount, rawDescriptor);

            ctx.phase = 'PATCH_21';
            ctx.subPhase = 21;
            ctx.mode = 'FILTERED_CUTLET_PARTITION_FAMILY_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_21_FILTERED_PARTITION_FAMILY';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch21.filteredPartitionFamily.calls');

            ctx.cutletPartitionCandidate = semanticPartition;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 21 rawCount=%s rawRank=%s semanticFamily=%s ', ...
                 'semanticCount=%s semanticRank=%s reusedLegacy=%d.'], ...
                char(rawFamilyCount), char(rawRank), ...
                semanticDescriptor.familyName, char(semanticCount), ...
                char(semanticRank), reusedLegacy);

            partition = semanticPartition;
        end
    end
end
