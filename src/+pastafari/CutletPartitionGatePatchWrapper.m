classdef CutletPartitionGatePatchWrapper
    % PATCH 21: semantic selection nad filtrowaną podrodziną.
    %
    % Raw legacy selection musi zostać wykonany wcześniej przez route.
    % Gdy nie ma internal gate, wrapper reuse dokładnie raw ghost.
    methods (Static)
        function [ctx, rank, partition, familyCount, descriptor, reusedLegacy] = ...
                callWithRing( ...
                    ctx, stream, gapCount, cutletCount, internalGateOffset, ...
                    rawRank, rawPartition, rawFamilyCount, rawDescriptor)
            pastafari.ValidationManager.requireContext(ctx);

            if isempty(internalGateOffset)
                rank = rawRank;
                partition = rawPartition;
                familyCount = rawFamilyCount;
                descriptor = rawDescriptor;
                reusedLegacy = true;
                return
            end

            descriptor = ...
                pastafari.FilteredLegacyCutletPartitionFamily.describe( ...
                    gapCount, cutletCount, internalGateOffset);
            familyCount = descriptor.count;

            if familyCount < pastafari.BigInt(1)
                error('Pastafari:Cutlets:FilteredPartitionEmpty', ...
                    'Filtrowana rodzina podziałów kotletów jest pusta.');
            end

            [ctx, rank] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    ctx, stream, familyCount);

            partition = ...
                pastafari.FilteredLegacyCutletPartitionFamily.unrank1( ...
                    gapCount, cutletCount, internalGateOffset, rank);
            reusedLegacy = false;
        end
    end
end
