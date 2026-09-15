classdef StructureSauceDetourPatch
    % PATCH 20: authoritative structure sauce używa pierwszego dnia roku.
    %
    % Ghost historyczny jest przekazywany osobno i nie jest modyfikowany.
    % Jeżeli originalTargetDay już jest firstDayOfYear, ghost może zostać
    % bezpiecznie użyty ponownie. W przeciwnym razie liczymy Sauce(c,firstDay).
    methods (Static)
        function [semanticSauce, reusedGhost] = apply( ...
                cDay, originalTargetDay, yearFirstDay, ghost)
            pastafari.ValidationManager.requireExactIntegerInput(cDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                originalTargetDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                yearFirstDay);

            calculationDay = pastafari.BigInt.coerce(cDay);
            originalTarget = pastafari.BigInt.coerce(originalTargetDay);
            firstDay = pastafari.BigInt.coerce(yearFirstDay);

            pastafari.StructureSauceDetourPatch.requireGhost(ghost);

            if ghost.calculationDay ~= calculationDay || ...
                    ghost.targetDay ~= originalTarget
                error('Pastafari:StructureSauce:GhostMismatch', ...
                    ['Historyczny ghost musi pochodzić dokładnie z ', ...
                     'Sauce(cDay,originalTargetDay).']);
            end

            if originalTarget == firstDay
                semanticSauce = ghost;
                reusedGhost = true;
            else
                semanticSauce = pastafari.sauceWithCurrentScars( ...
                    calculationDay, firstDay);
                reusedGhost = false;
            end

            if semanticSauce.calculationDay ~= calculationDay || ...
                    semanticSauce.targetDay ~= firstDay
                error('Pastafari:StructureSauce:AuthoritativeTargetMismatch', ...
                    ['Semantic structure sauce musi być dokładnie ', ...
                     'Sauce(cDay,firstDayOfYear).']);
            end
        end
    end

    methods (Static, Access = private)
        function requireGhost(ghost)
            if ~isstruct(ghost) || ...
                    ~isfield(ghost, 'calculationDay') || ...
                    ~isfield(ghost, 'targetDay') || ...
                    ~isfield(ghost, 'bowls') || ...
                    ~isfield(ghost, 'orderAt46Latch') || ...
                    ~isfield(ghost, 'bowl2')
                error('Pastafari:StructureSauce:GhostShape', ...
                    ['Historyczny ghost wymaga calculationDay, targetDay, ', ...
                     'bowls, orderAt46Latch i bowl2.']);
            end

            pastafari.ValidationManager.requireExactIntegerInput( ...
                ghost.calculationDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                ghost.targetDay);
            pastafari.ValidationManager.requireExactIntegerInput(ghost.bowl2);
        end
    end
end
