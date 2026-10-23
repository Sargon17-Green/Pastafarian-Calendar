function [word, receipt] = unrankWholeWeavingNearEdge(monthLengths, distance, edge)
% Eksperyment: dokladna ranga blisko poczatku lub konca rodziny
% bez wyliczania ogromnych blokow DP/BigInt. Nie jest to
% ogolny szybki unrank rangi wewnetrznej.
%
% distance = 0 daje pierwsze/ostatnie legalne slowo.
% distance = d wybiera odpowiednio range 1+d lub count-d,
% poprzez dokladnie d sasiednich legalnych slow.
% Algorytm NIGDY nie przeskakuje rangi i nie przybliza wyniku;
% gdy odleglosc wykracza poza rodzine, jawnie odrzuca zadanie.
% Czas O(distance * K * N); pamiec O(K+N).
%
% Uzywa natywnie zweryfikowanych dwoch niezaleznych krokow:
% extremalWholeMonthWeavings i adjacentWholeMonthWeaving.
% Produkcyjny DAG, normative oracle i main bez zmian.

if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
        ~isempty(monthLengths) && isreal(monthLengths) && ...
        all(isfinite(monthLengths)) && ...
        all(monthLengths>0) && all(fix(monthLengths)==monthLengths) && ...
        all(monthLengths<=flintmax))
    error('Pastafari:NearEdge:Lengths', ...
        'Month lengths must be positive exact integers.');
end
L=double(monthLengths(:).');
if ~(isnumeric(distance) && isscalar(distance) && ...
        isreal(distance) && isfinite(distance) && ...
        distance>=0 && fix(distance)==distance && ...
        distance<=flintmax)
    error('Pastafari:NearEdge:Distance', ...
        'Distance must be a nonnegative exact integer.');
end
if ~(ischar(edge) && isrow(edge) && ...
        (strcmp(edge,'first') || strcmp(edge,'last')))
    error('Pastafari:NearEdge:Edge', ...
        'Edge must be first or last.');
end
[first,last]=pastafari.extremalWholeMonthWeavings(L);
if strcmp(edge,'first')
    word=first;
    direction='next';
else
    word=last;
    direction='previous';
end
for k=1:distance
    [neighbor,found]=pastafari.adjacentWholeMonthWeaving( ...
        word,L,direction);
    if ~found
        error('Pastafari:NearEdge:OutOfRange', ...
            'Requested exact distance exceeds the lexical family.');
    end
    word=neighbor;
end
receipt=struct('edge',edge,'distance',double(distance), ...
    'days',numel(word),'months',numel(L), ...
    'allStepsCompleted',true);
end
