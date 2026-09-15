function [weaving, proposals, remaining] = ...
        legacyChooseEachDaySeparately(stream, monthLengths)
% Historyczna wada Discovery 24.
%
% Każdy dzień pyta answer ring niezależnie o month id modulo monthCount.
% Jeśli proponowany miesiąc jest już pełny, skanuje cyklicznie do pierwszego
% niepełnego miesiąca. Zachowuje multiplicities, ale nie wymusza legalnego
% porządku pierwszych ani ostatnich wystąpień miesięcy.

if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
        ~isempty(monthLengths) && all(isfinite(monthLengths)) && ...
        all(fix(monthLengths) == monthLengths) && all(monthLengths > 0))
    error('Pastafari:MonthWeaving:LegacyLengths', ...
        'monthLengths musi być niepustym dodatnim wektorem całkowitym.');
end

lengths = double(monthLengths(:).');
monthCount = numel(lengths);
totalDays = sum(lengths);

weaving = zeros(1, totalDays);
proposals = zeros(1, totalDays);
remaining = lengths;

for dayIndex = 0:(totalDays - 1)
    answer = pastafari.AnswerRingStreamFactory.answerAt( ...
        stream, pastafari.BigInt(dayIndex));
    zeroBased = (answer - pastafari.BigInt(1)).regularMod( ...
        pastafari.BigInt(monthCount));
    proposed = zeroBased.toDoubleExact() + 1;
    proposals(dayIndex + 1) = proposed;

    selected = proposed;
    found = false;
    for skip = 1:monthCount
        if remaining(selected) > 0
            found = true;
            break
        end
        selected = pastafari.wrapMonth(selected + 1, monthCount);
    end

    if ~found
        error('Pastafari:MonthWeaving:LegacyNoRemainingMonth', ...
            'Nie znaleziono miesiąca z pozostałą pojemnością.');
    end

    weaving(dayIndex + 1) = selected;
    remaining(selected) = remaining(selected) - 1;
end

if any(remaining ~= 0)
    error('Pastafari:MonthWeaving:LegacyMultiplicityInvariant', ...
        'Historyczny chooser nie zużył dokładnie wszystkich multiplicities.');
end
end
