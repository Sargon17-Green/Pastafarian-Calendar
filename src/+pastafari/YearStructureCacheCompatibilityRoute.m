classdef YearStructureCacheCompatibilityRoute
    % Produkcyjna trasa structure cache po PATCH 19.
    %
    % Najpierw zawsze wykonuje historyczny raw lookup keyed tylko przez
    % year.number i zachowuje jego hit/value/entry jako bliznę. Następnie
    % semantic reuse wymaga fingerprint + openGate + closeGate.
    methods (Static)
        function [ctx, value] = call( ...
                ctx, year, calculationDay, producer)
            pastafari.ValidationManager.requireContext(ctx);
            pastafari.ValidationManager.requireExactIntegerInput( ...
                calculationDay);

            if ~isa(producer, 'function_handle')
                error('Pastafari:Cache:Producer', ...
                    'Structure cache wymaga function handle producenta.');
            end

            cDay = pastafari.BigInt.coerce(calculationDay);
            if pastafari.BigInt.coerce(ctx.calculationDay) ~= cDay
                error('Pastafari:Cache:ContextCalculationDay', ...
                    ['calculationDay cache musi należeć do bieżącego ', ...
                     'MonsterContext.']);
            end

            % Surowa historyczna blizna Discovery 19.
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_19_BAD_YEAR_CACHE_KEY';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery19.badYearCacheKey.calls');

            [rawValueBefore, rawHit, rawEntryBefore] = ...
                pastafari.LegacyYearNumberStructureCache.getRaw(year);

            % PATCH 19: semantic guard nad tym samym fizycznym key.
            ctx.phase = 'PATCH_19';
            ctx.subPhase = 19;
            ctx.mode = 'GUARDED_YEAR_CACHE_ACTIVE';
            ctx.status = 'PATCHED_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'PATCH_19_GUARDED_YEAR_CACHE';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'patch19.guardedYearCache.calls');

            [value, guardHit, recomputed, committedEntry] = ...
                pastafari.GuardedYearCachePatch.apply( ...
                    year, cDay, producer, rawHit, rawEntryBefore);

            % Zachowaj dokładny obraz Stage 38 sprzed ewentualnego overwrite.
            ctx.legacyYearCacheKey = ...
                pastafari.BigInt.coerce(year.number);
            ctx.legacyYearCacheHit = rawHit;

            if rawHit
                ctx.legacyYearCacheEntryCalculationDayFingerprint = ...
                    rawEntryBefore.calculationDayFingerprint;
                ctx.legacyYearCacheEntryOpenGate = rawEntryBefore.openGate;
                ctx.legacyYearCacheEntryCloseGate = rawEntryBefore.closeGate;
                ctx.legacyYearCacheRawValue = rawValueBefore;
                ctx.legacyYearCacheProducerExecuted = false;
            else
                % W Stage 38 cold miss uruchamiał producenta i dopiero potem
                % zapisywał raw entry. Zachowujemy ten sam obserwowalny ślad.
                ctx.legacyYearCacheEntryCalculationDayFingerprint = ...
                    committedEntry.calculationDayFingerprint;
                ctx.legacyYearCacheEntryOpenGate = committedEntry.openGate;
                ctx.legacyYearCacheEntryCloseGate = committedEntry.closeGate;
                ctx.legacyYearCacheRawValue = value;
                ctx.legacyYearCacheProducerExecuted = recomputed;
            end

            ctx.yearStructureCandidate = value;
            ctx.diagnostics{end + 1} = sprintf( ...
                ['PATCH 19 rawHit=%d, guardHit=%d, recomputed=%d; ', ...
                 'physical key nadal year.number.'], ...
                rawHit, guardHit, recomputed);
        end
    end
end
