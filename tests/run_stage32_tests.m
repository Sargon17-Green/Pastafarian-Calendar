function run_stage32_tests()
% DISCOVERY 16: legacy generator dopuszcza rok do 5781 dni.
% Raw kandydaci 5779..5781 mają pozostać po PATCH 16, natomiast
% publikowana lista ma wtedy przejść przez late max-5778 filter.

run_stage31_tests();

here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(fullfile(root, 'src'));
cleanup = onCleanup(@() cleanupPaths(root)); %#ok<NASGU>

lengths = [251 252 5778 5779 5780 5781 5782 300];
gateSpans = [6 6 6 6 6 6 6 5];

rawCandidates = cell(1, numel(lengths));
for k = 1:numel(lengths)
    rawCandidates{k} = makeCandidate(k, gateSpans(k), lengths(k));
end

[legacyAccepted, legacyLengths] = ...
    pastafari.LegacyYearMax5781Filter.apply(rawCandidates);

legacyValues = toDoubleRow(legacyLengths);
assert(isequal(legacyValues, [252 5778 5779 5780 5781]), ...
    'Historyczny max 5781 ma nieoczekiwany zestaw kandydatów.');

normativeAccepted = normativeFilter(rawCandidates);
normativeValues = candidateLengths(normativeAccepted);
assert(isequal(normativeValues, [252 5778]), ...
    'Normatywny max 5778 ma nieoczekiwany zestaw kandydatów.');

ctx = pastafari.MonsterContext(0, 0);
[ctx, actualCandidates] = ...
    pastafari.YearCandidateCompatibilityRoute.call(ctx, rawCandidates);

assert(ctx.legacyYearMaxDays == pastafari.BigInt(5781), ...
    'Kontekst utracił historyczny max 5781.');
assert(isequal( ...
    toDoubleRow(ctx.legacyYearCandidateLengths), legacyValues), ...
    'Kontekst utracił raw legacy lengths.');
assert(isequal( ...
    candidateLengths(ctx.legacyYearCandidatesAccepted), legacyValues), ...
    'Kontekst utracił raw legacy candidates.');

assert(any(strcmp(ctx.branchTrace, ...
    'DISCOVERY_16_LEGACY_YEAR_MAX_5781')), ...
    'Brakuje śladu Discovery 16.');
metricKey = matlab.lang.makeValidName( ...
    'discovery16.legacyYearMax5781.calls');
assert(isfield(ctx.metrics, metricKey) && ctx.metrics.(metricKey) == 1, ...
    'Licznik legacy-year-max-5781 jest niepoprawny.');

publishedValues = candidateLengths(actualCandidates);

rawPattern = isequal(publishedValues, legacyValues);
greenPattern = isequal(publishedValues, normativeValues);
assert(rawPattern || greenPattern, ...
    ['Stage 32 powinno publikować raw 5781 przed PATCH 16 albo ', ...
     'dokładny late-filtered zestaw po PATCH 16.']);

extraLegacy = setdiff(legacyValues, normativeValues, 'stable');
assert(isequal(extraLegacy, [5779 5780 5781]), ...
    'Historyczna blizna powinna składać się dokładnie z 5779..5781.');

fprintf(['STAGE32 DISCOVERY16 RAW=[%s] ACTUAL=[%s] ', ...
    'EXPECTED=[%s] CLASSIFICATION=%s\n'], ...
    rowText(legacyValues), rowText(publishedValues), ...
    rowText(normativeValues), classification(rawPattern));

foundation = pastafari.BigInt('-15055671');
caught = false;
try
    calendarDateSpaghetti(foundation, foundation);
catch err
    caught = strcmp(err.identifier, 'Pastafari:Bootstrap:NotImplementedYet');
end
assert(caught, ...
    'Publiczna trasa nie zachowała kontrolowanej granicy etapu 32.');

if rawPattern
    fprintf('STAGE_32_DISCOVERY_16_EXPECTED_RED\n');
    error('Pastafari:Discovery16:LegacyYearMax5781', ...
        ['Oczekiwana rozbieżność Discovery 16: kandydaci roku ', ...
         '5779..5781 są nadal publikowani.']);
end

fprintf('STAGE_32_DISCOVERY_16_REGRESSION_GREEN\n');
end

function candidate = makeCandidate(id, gateSpan, lengthDays)
candidate = struct( ...
    'id', id, ...
    'openGateIndex', pastafari.BigInt(0), ...
    'closeGateIndex', pastafari.BigInt(gateSpan), ...
    'openGateDay', pastafari.BigInt(10000 + id * 10000), ...
    'closeGateDay', ...
        pastafari.BigInt(10000 + id * 10000 + lengthDays));
end

function accepted = normativeFilter(candidates)
accepted = {};
for k = 1:numel(candidates)
    c = candidates{k};
    gateSpan = pastafari.BigInt.coerce(c.closeGateIndex) - ...
        pastafari.BigInt.coerce(c.openGateIndex);
    lengthDays = pastafari.BigInt.coerce(c.closeGateDay) - ...
        pastafari.BigInt.coerce(c.openGateDay);

    if gateSpan >= pastafari.BigInt(6) && ...
            lengthDays >= pastafari.BigInt(252) && ...
            lengthDays <= pastafari.BigInt(5778)
        accepted{end + 1} = c; %#ok<AGROW>
    end
end
end

function values = candidateLengths(candidates)
values = zeros(1, numel(candidates));
for k = 1:numel(candidates)
    values(k) = ( ...
        pastafari.BigInt.coerce(candidates{k}.closeGateDay) - ...
        pastafari.BigInt.coerce(candidates{k}.openGateDay)).toDoubleExact();
end
end

function values = toDoubleRow(items)
values = zeros(1, numel(items));
for k = 1:numel(items)
    values(k) = pastafari.BigInt.coerce(items{k}).toDoubleExact();
end
end

function text = rowText(values)
text = strtrim(sprintf('%d ', values));
end

function text = classification(isRed)
if isRed
    text = 'EXPECTED_RED';
else
    text = 'MATCH';
end
end

function cleanupPaths(root)
rmpath(fullfile(root, 'src'));
end
