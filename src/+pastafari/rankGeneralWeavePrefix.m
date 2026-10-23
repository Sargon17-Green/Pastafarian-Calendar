function [firstRank, lastRank, cursor] = rankGeneralWeavePrefix( ...
        originalLengths, remaining, openedUpTo, closedUpTo, prefix, method)
% Eksperymentalny DOKLADNY przedzial 1-indeksowanych rang dla dowolnego
% osiagnietego frontieru miesiecy — rowniez przed ich otwarciem.
% Odwrotny kierunek wzgledem unrankGeneralWeaveSuffixChunkLazyJoint.
% Bez zmian w silniku produkcyjnym, main i normative_oracle.
%
% W kazdym stanie legalne nastepne litery dziela wszystkie dopelnienia
% na rozlaczne bloki B_i. Dodajemy B_i dla i < zadana litera, a nastepnie
% przechodzimy do jej dokladnego podzbioru. Pusty prefiks obejmuje
% caly zakres [1,F], a pelny poprawny prefiks jedna range.
%
% method='joint': wspolny exact next-letter DP przy >=2 nieotwartych
% miesiacach; metoda dwumianowa przy <=1 nieotwartym miesiacu.
% method='reference': oddzielny exact first-endpoint count kazdego
% dziecka, z niezalezna kontrola sumy blokow.
if nargin<6
    method='joint';
end
if ~(ischar(method) && isrow(method) && ...
        (strcmp(method,'joint') || strcmp(method,'reference')))
    error('Pastafari:GeneralPrefixRank:Method', ...
        'Only joint or reference exact methods are supported.');
end
if ~(isnumeric(originalLengths) && isvector(originalLengths) && ...
        ~isempty(originalLengths) && isreal(originalLengths) && ...
        all(isfinite(originalLengths(:))) && ...
        all(originalLengths(:)>0) && ...
        all(fix(originalLengths(:))==originalLengths(:)) && ...
        all(originalLengths(:)<=flintmax))
    error('Pastafari:GeneralPrefixRank:Lengths', ...
        'Original lengths must be positive exact integers.');
end
L=double(originalLengths(:).');
K=numel(L);
if ~(isnumeric(remaining) && isvector(remaining) && ...
        numel(remaining)==K && isreal(remaining) && ...
        all(isfinite(remaining(:))) && ...
        all(fix(remaining(:))==remaining(:)) && ...
        all(remaining(:)>=0))
    error('Pastafari:GeneralPrefixRank:Remaining', ...
        'Remaining lengths must be exact nonnegative integers.');
end
R=double(remaining(:).');
if any(R>L)
    error('Pastafari:GeneralPrefixRank:Remaining', ...
        'Remaining multiplicities exceed original month lengths.');
end
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isreal(openedUpTo) && isfinite(openedUpTo) && ...
        fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isreal(closedUpTo) && isfinite(closedUpTo) && ...
        fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K) || ...
        any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:openedUpTo)<=0) || ...
        any(R(closedUpTo+1:openedUpTo)>=L(closedUpTo+1:openedUpTo)) || ...
        any(R(openedUpTo+1:end)~=L(openedUpTo+1:end))
    error('Pastafari:GeneralPrefixRank:Frontier', ...
        'Opening/closure frontier and remaining counts disagree.');
end
if ~(isnumeric(prefix) && (isempty(prefix) || isvector(prefix)) && ...
        isreal(prefix) && all(isfinite(prefix(:))) && ...
        all(fix(prefix(:))==prefix(:)) && ...
        all(prefix(:)>=1) && all(prefix(:)<=K))
    error('Pastafari:GeneralPrefixRank:Prefix', ...
        'Prefix must consist of exact month IDs.');
end
word=double(prefix(:).');
N=sum(R);
if ~isfinite(N) || N>flintmax || numel(word)>N
    error('Pastafari:GeneralPrefixRank:Days', ...
        'Prefix exceeds exact remaining day count.');
end

one=pastafari.BigInt(1);
zero=pastafari.BigInt(0);
count=zero;
known=false;
whole=zero;
firstRank=one;
for position=1:numel(word)
    blocks=cell(1,K);
    if openedUpTo<K-1 && strcmp(method,'joint')
        [blocks,reportedParent]= ...
            pastafari.countWholeWeavingNextLetterBlocksOnePass( ...
                R,openedUpTo,closedUpTo);
        if known && reportedParent~=count
            error('Pastafari:GeneralPrefixRank:CountMismatch', ...
                'Joint parent count conflicts with selected child.');
        end
        count=reportedParent;
        known=true;
    else
        if ~known
            count=countAtFrontier(R,openedUpTo,closedUpTo,method);
            known=true;
        end
        if openedUpTo==K && strcmp(method,'joint')
            blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
                R,closedUpTo,count);
        else
            for i=closedUpTo+1:K
                n=R(i);
                if n==0 || (n==L(i) && i~=openedUpTo+1) || ...
                        (n==1 && i~=closedUpTo+1)
                    continue
                end
                child=R;
                child(i)=n-1;
                childOpened=openedUpTo+double(n==L(i));
                childClosed=closedUpTo+double(n==1);
                blocks{i}=countAtFrontier(child,childOpened, ...
                    childClosed,method);
            end
        end
    end
    if position==1
        whole=count;
    end
    selected=word(position);
    block=blocks{selected};
    if isempty(block) || block<one
        error('Pastafari:GeneralPrefixRank:IllegalLetter', ...
            'Prefix illegally opens/closes a month or duplicates a day.');
    end
    partition=zero;
    for i=1:K
        if isempty(blocks{i})
            continue
        end
        if blocks{i}<one
            error('Pastafari:GeneralPrefixRank:Block', ...
                'Every legal child must have a positive exact count.');
        end
        partition=partition+blocks{i};
        if i<selected
            firstRank=firstRank+blocks{i};
        end
    end
    if partition~=count
        error('Pastafari:GeneralPrefixRank:Partition', ...
            'Lexical child blocks do not sum to the exact parent.');
    end
    n=R(selected);
    R(selected)=n-1;
    openedUpTo=openedUpTo+double(n==L(selected));
    closedUpTo=closedUpTo+double(n==1);
    count=block;
end
if ~known
    count=countAtFrontier(R,openedUpTo,closedUpTo,method);
    whole=count;
end
lastRank=firstRank+count-one;
if firstRank<one || lastRank<firstRank || lastRank>whole
    error('Pastafari:GeneralPrefixRank:Rank', ...
        'Prefix interval must lie within exact original family.');
end
done=all(R==0);
if done && (openedUpTo~=K || closedUpTo~=K || ...
        count~=one || firstRank~=lastRank)
    error('Pastafari:GeneralPrefixRank:Terminal', ...
        'Complete word must have one exact rank and all months closed.');
end
cursor=struct('remaining',R,'openedUpTo',openedUpTo, ...
    'closedUpTo',closedUpTo,'count',count,'done',done, ...
    'totalCount',whole,'firstRank',firstRank, ...
    'lastRank',lastRank,'stepsComputed',numel(word));
end

function count=countAtFrontier(R,o,c,method)
% Terminal state is one empty completion by definition.
if all(R==0)
    count=pastafari.BigInt(1);
elseif strcmp(method,'joint') && o>=numel(R)-1
    count=pastafari.countWholeWeavingSuffixByEndpoints(R,o,c);
else
    count=pastafari.countWholeWeavingSuffixByFirstEndpoint(R,o,c);
end
end
