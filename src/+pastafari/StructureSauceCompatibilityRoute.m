classdef StructureSauceCompatibilityRoute
    % Produkcyjna trasa Discovery 20.
    %
    % Stage 40 publikuje jeszcze oldStructureSauce(cDay, originalTargetDay).
    % Pierwszy dzień roku jest znany, ale nie jest używany do semantic sauce.
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

            ctx.phase = 'DISCOVERY_20';
            ctx.subPhase = 20;
            ctx.mode = 'OLD_STRUCTURE_SAUCE_TARGET';
            ctx.status = 'LEGACY_PATH_ACTIVE';
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
            ctx.structureSauceCandidate = ghost;
            ctx.structureSauceBowl2Candidate = ghost.bowl2;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 20 używa originalTargetDay do structure sauce; ', ...
                 'znany yearFirstDay=openGateDay+1 pozostaje zignorowany.'];

            sauceResult = ghost;
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
