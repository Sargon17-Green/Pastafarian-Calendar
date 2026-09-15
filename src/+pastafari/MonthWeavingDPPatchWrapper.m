classdef MonthWeavingDPPatchWrapper
    % PATCH 24: whole-weave DP detour.
    %
    % Ghost historyczny musi zostać wykonany wcześniej. Wrapper wybiera jeden
    % rank dla całego legalnego splotu, wykonuje exact DP unrank i zwraca
    % ghost wyłącznie wtedy, gdy ghost jest dokładnie równy poprawnemu wynikowi.
    methods (Static)
        function [ctx, familyCount, rank, result, correct, reusedGhost] = ...
                callWithRing(ctx, stream, monthLengths, ghost)
            pastafari.ValidationManager.requireContext(ctx);

            if ~(isnumeric(ghost) && isvector(ghost))
                error('Pastafari:MonthWeaving:GhostShape', ...
                    'Historyczny month-weaving ghost musi być wektorem.');
            end

            family = pastafari.WholeMonthWeavingFamily(monthLengths);
            familyCount = family.count();

            if familyCount < pastafari.BigInt(1)
                error('Pastafari:MonthWeaving:WholeFamilyEmpty', ...
                    'Legalna whole-weave family jest pusta.');
            end

            [ctx, rank] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    ctx, stream, familyCount);

            correct = family.itemAt1(rank);

            if isequal(double(ghost(:).'), correct)
                result = double(ghost(:).');
                reusedGhost = true;
            else
                result = correct;
                reusedGhost = false;
            end
        end
    end
end
