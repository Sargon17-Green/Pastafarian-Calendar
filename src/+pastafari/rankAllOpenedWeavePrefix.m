function [firstRank, lastRank, cursor] = rankAllOpenedWeavePrefix( ...
        remaining, closedUpTo, prefix, method)
% EKSPERYMENTALNY dokladny przedzial rang leksykograficznych dla
% prefiksu legalnego splotu, w ktorym wszystkie miesiace sa
% JUZ OTWARTE. Nie jest to ranking pelnej nieotwartej rodziny roku.
%
% Dla prefiksu P wszystkie legalne slowa zaczynajace sie od P
% tworza jeden spojny przedzial rang [firstRank,lastRank].
% Szerokosc przedzialu to dokladnie liczba legalnych dopelnien
% prefiksu. Dla pelnego slowa firstRank=lastRank.
%
% Po kazdej literze sumujemy DOKLADNE bloki dzieci o mniejszym ID,
% obliczone z tego samego rodzica. Nigdy nie uzywamy double do
% licznosci ani do operacji na rangach. Produkcja i main bez zmian.
if nargin<4
    method='common';
end
if ~(ischar(method) && isrow(method) && ...
        (strcmp(method,'common') || strcmp(method,'rational')))
    error('Pastafari:AllOpenPrefixRank:Method', ...
        'Only common or rational exact child blocks are supported.');
end
if ~(isnumeric(remaining) && isvector(remaining) && ...
        ~isempty(remaining) && isreal(remaining) && ...
        all(isfinite(remaining(:))) && all(remaining(:)>=0) && ...
        all(fix(remaining(:))==remaining(:)) && ...
        all(remaining(:)<=flintmax))
    error('Pastafari:AllOpenPrefixRank:Remaining', ...
        'Expected a nonempty vector of exact nonnegative counts.');
end
R=double(remaining(:).');
K=numel(R);
if ~(isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isreal(closedUpTo) && isfinite(closedUpTo) && ...
        fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=K) || ...
        any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:end)<=0)
    error('Pastafari:AllOpenPrefixRank:Frontier', ...
        'The all-open closed prefix and remaining counts conflict.');
end
if ~(isnumeric(prefix) && (isempty(prefix) || isvector(prefix)) && ...
        isreal(prefix) && all(isfinite(prefix(:))) && ...
        all(fix(prefix(:))==prefix(:)) && ...
        all(prefix(:)>=1) && all(prefix(:)<=K))
    error('Pastafari:AllOpenPrefixRank:Prefix', ...
        'Prefix must contain exact legal month IDs.');
end
word=double(prefix(:).');
N=sum(R);
if ~isfinite(N) || N>flintmax || numel(word)>N
    error('Pastafari:AllOpenPrefixRank:Days', ...
        'Prefix cannot exceed the exact remaining suffix length.');
end
one=pastafari.BigInt(1);
if N==0
    count=one;
else
    count=pastafari.countWholeWeavingSuffixByEndpoints(R,K,closedUpTo);
end
whole=count;
firstRank=one;
for position=1:numel(word)
    if strcmp(method,'common')
        blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
            R,closedUpTo,count);
    else
        blocks=pastafari.allOpenedWholeWeaveChildCounts( ...
            R,closedUpTo,count);
    end
    selected=word(position);
    block=blocks{selected};
    if isempty(block) || block<one
        error('Pastafari:AllOpenPrefixRank:IllegalLetter', ...
            'Requested prefix closes a month out of order or reuses it.');
    end
    for i=closedUpTo+1:selected-1
        if ~isempty(blocks{i})
            firstRank=firstRank+blocks{i};
        end
    end
    R(selected)=R(selected)-1;
    if R(selected)==0
        if selected~=closedUpTo+1
            error('Pastafari:AllOpenPrefixRank:Closure', ...
                'Canonical closure order was violated.');
        end
        closedUpTo=closedUpTo+1;
    end
    count=block;
end
lastRank=firstRank+count-one;
if firstRank<one || lastRank>whole || lastRank<firstRank
    error('Pastafari:AllOpenPrefixRank:Interval', ...
        'The exact prefix interval exceeds original family count.');
end
done=closedUpTo==K;
if done && (count~=one || any(R~=0) || firstRank~=lastRank)
    error('Pastafari:AllOpenPrefixRank:Terminal', ...
        'Terminal full-word prefix must identify one exact rank.');
end
cursor=struct('remaining',R,'closedUpTo',closedUpTo, ...
    'count',count,'done',done,'stepsComputed',numel(word), ...
    'totalCount',whole,'firstRank',firstRank,'lastRank',lastRank);
end
