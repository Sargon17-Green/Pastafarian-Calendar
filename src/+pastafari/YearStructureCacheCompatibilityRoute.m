classdef YearStructureCacheCompatibilityRoute
    % Produkcyjna trasa Discovery 19.
    %
    % Raw lookup jest keyed wyłącznie przez year.number. Jeżeli istnieje
    % entry, Stage 38 publikuje jego value bez sprawdzania fingerprintu
    % calculationDay ani obu gate days.
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

            ctx.phase = 'DISCOVERY_19';
            ctx.subPhase = 19;
            ctx.mode = 'YEAR_NUMBER_ONLY_CACHE_KEY';
            ctx.status = 'LEGACY_PATH_ACTIVE';
            ctx.branchTrace{end + 1} = ...
                'DISCOVERY_19_BAD_YEAR_CACHE_KEY';
            ctx.metrics = pastafari.MetricsShell.bump( ...
                ctx.metrics, 'discovery19.badYearCacheKey.calls');

            [rawValue, rawHit, entry] = ...
                pastafari.LegacyYearNumberStructureCache.getRaw(year);

            producerExecuted = false;
            if ~rawHit
                rawValue = producer();
                producerExecuted = true;
                pastafari.LegacyYearNumberStructureCache.put( ...
                    year, cDay, rawValue);
                [entry, stored] = ...
                    pastafari.LegacyYearNumberStructureCache.getEntry(year);
                if ~stored
                    error('Pastafari:Cache:LegacyCommitLost', ...
                        'Historyczny cache utracił właśnie zapisany entry.');
                end
            end

            ctx.legacyYearCacheKey = ...
                pastafari.BigInt.coerce(year.number);
            ctx.legacyYearCacheHit = rawHit;
            ctx.legacyYearCacheEntryCalculationDayFingerprint = ...
                entry.calculationDayFingerprint;
            ctx.legacyYearCacheEntryOpenGate = entry.openGate;
            ctx.legacyYearCacheEntryCloseGate = entry.closeGate;
            ctx.legacyYearCacheRawValue = rawValue;
            ctx.legacyYearCacheProducerExecuted = producerExecuted;
            ctx.yearStructureCandidate = rawValue;
            ctx.diagnostics{end + 1} = ...
                ['Discovery 19 ufa hitowi po samym year.number; ', ...
                 'fingerprint i gate days są zapisane, lecz ignorowane.'];

            value = rawValue;
        end
    end
end
