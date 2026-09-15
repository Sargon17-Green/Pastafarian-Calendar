classdef StructureSauceCompatibilityRoute
    % Produkcyjna trasa structure sauce po PATCH 20.
    %
    % Najpierw zawsze wykonuje realny historyczny ghost
    % oldStructureSauce(cDay,originalTargetDay) i zachowuje go jako bliznę.
    % Semantic path używa Sauce(cDay,openGateDay+1).
    methods (Static)
        function [ctx, sauceResult] = call( ...
                ctx, cDay, originalTargetDay, year)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput(cDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                originalTargetDay);
            pastafari.StructureSauceCompatibilityRoute.requireYear(year);

            calculationDay = pastafari.BigInt.coerce(cDay);
            originalTarget = pastafari.BigInt.coerce(originalTargetDay);
            yearFirstDay = ...
                pastafari.BigInt.coerce(year.openGateDay) + ...
                pastafari.BigInt(1);

            if pastafari.BigInt.coerce(ctx.calculationDay) ~= calculationDay
                error('Pastafari:StructureSauce:ContextCalculationDay', ...
                    'cDay structure sauce musi należeć do bieżącego context.');
            end

            % Surowa historyczna blizna Discovery 20.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_20_OLD_STRUCTURE_SAUCE_TARGET';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery20.oldStructureSauceTarget.calls');

            ghost = pastafari.oldStructureSauce( ...
                calculationDay, originalTarget);

            ctx.structureSauceCalculationDay = calculationDay;
            ctx.structureSauceOriginalTargetDay = originalTarget;
            ctx.structureSauceYearFirstDay = yearFirstDay;
            ctx.legacyStructureSauce = ghost;
            ctx.legacyStructureSauceBowl2 = ghost.bowl2;
            ctx.legacyStructureSauceOrderAt46 = ghost.orderAt46Latch;

            % PATCH 20: autorytatywny target struktury to pierwszy dzień roku.
            ctx.phase = 'PATCH_20';
            ctx.subPhase = 20;
            ctx.mode = 'AUTHORITATIVE_FIRST_DAY_STRUCTURE_SAUCE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_20_STRUCTURE_SAUCE_DETOUR';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch20.structureSauceDetour.calls');

            [semanticSauce, reusedGhost] = ...
                pastafari.StructureSauceDetourPatch.apply( ...
                    calculationDay, originalTarget, yearFirstDay, ghost);

            ctx.structureSauceCandidate = semanticSauce;
            ctx.structureSauceBowl2Candidate = semanticSauce.bowl2;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 20 zachowuje ghost target=%s, ale publikuje ', ...
                 'firstDayOfYear=%s; reusedGhost=%d.'], ...
                char(originalTarget), char(yearFirstDay), reusedGhost);

            sauceResult = semanticSauce;
        end
    end

    methods (Static, Access = private)
        function requireYear(year)
            if ~isstruct(year) || ...
                    ~isfield(year, 'number') || ...
                    ~isfield(year, 'openGateDay') || ...
                    ~isfield(year, 'closeGateDay')
                error('Pastafari:StructureSauce:YearShape', ...
                    ['Structure sauce wymaga year.number, openGateDay ', ...
                     'i closeGateDay.']);
            end

            pastafari.ValidationManager.requireExactIntegerInput(year.number);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.openGateDay);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                year.closeGateDay);
        end
    end
end
