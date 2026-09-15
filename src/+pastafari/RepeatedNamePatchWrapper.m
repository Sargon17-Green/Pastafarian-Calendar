classdef RepeatedNamePatchWrapper
    % PATCH 22: distinct-name detour po realnym legacy candidate.
    %
    % LegacyRepeatedNameGenerator musi zostać wykonany wcześniej przez route.
    % Correct candidate pochodzi z tej samej answer-ring ścieżki, ale z
    % falling-factorial family i partial-permutation lexicographic unrank.
    methods (Static)
        function [ctx, rank, candidate, familyCount, reusedLegacy] = ...
                callWithRing( ...
                    ctx, stream, masterCount, outputCount, badCandidate)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(masterCount);
            pastafari.ValidationManager.requireExactIntegerInput(outputCount);

            master = pastafari.BigInt.coerce(masterCount);
            outputs = pastafari.BigInt.coerce(outputCount);

            if outputs < pastafari.BigInt(1) || outputs > master
                error('Pastafari:Names:DistinctShape', ...
                    'Distinct name row wymaga 1<=outputCount<=masterCount.');
            end

            K = outputs.toDoubleExact();
            if ~(isnumeric(badCandidate) && isvector(badCandidate) && ...
                    numel(badCandidate) == K)
                error('Pastafari:Names:LegacyCandidateShape', ...
                    'Legacy name candidate ma niepoprawny kształt.');
            end

            familyCount = ...
                pastafari.partialPermutationNameRowCount(master, outputs);

            [ctx, rank] = ...
                pastafari.GeneralSelectionCompatibilityRoute.call( ...
                    ctx, stream, familyCount);

            correct = pastafari.partialPermutationNameRowUnrank( ...
                master, outputs, rank);

            if isequal(badCandidate(:).', correct)
                candidate = badCandidate(:).';
                reusedLegacy = true;
            else
                candidate = correct;
                reusedLegacy = false;
            end
        end
    end
end
