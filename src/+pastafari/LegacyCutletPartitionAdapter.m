classdef LegacyCutletPartitionAdapter
    % Historyczna selekcja Discovery 21 nad pełną rodziną dodatnich kompozycji.
    %
    % Adapter celowo nie przyjmuje internalGateOffset.
    methods (Static)
        function [ctx, rank, partition, familyCount, descriptor] = ...
                callWithRing(ctx, stream, gapCount, cutletCount)
            pastafari.ValidationManager.requireContext(ctx);

            descriptor = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.describe( ...
                    gapCount, cutletCount);
            familyCount = descriptor.count;

            if familyCount < pastafari.BigInt(1)
                error('Pastafari:Cutlets:LegacyPartitionEmpty', ...
                    'Historyczna rodzina dodatnich kompozycji jest pusta.');
            end

            [ctx, rank] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    ctx, stream, familyCount);

            partition = ...
                pastafari.LegacyAllPositiveCutletPartitionFamily.unrank1( ...
                    gapCount, cutletCount, rank);
        end
    end
end
