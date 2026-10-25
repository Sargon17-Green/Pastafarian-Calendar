function [piece, cursor] = unrankGeneralWeaveSuffixChunkAdjoint( ...
        originalLengths, remaining, openedUpTo, closedUpTo, rank1, maxSteps)
% EKSPERYMENT: adjoint two-sweep exact lexical unrank, bez wstępnego,
% redundantnego przeliczenia rodzica dla prefiksów wymuszonych.
% Pozostawia dawną trasę oraz kod produkcyjny bez zmian.
%
% Do pierwszego rzeczywistego rozgałęzienia wybory są wymuszone.
% Doklejenie wymuszonej litery jest bijekcją legalnych dokończeń,
% więc liczba i rank pozostają identyczne. Przy rozgałęzieniu
% wspólny dokładny licznik dostarcza jednocześnie liczbę rodzica
% i wszystkie bloki pierwszej litery. Nigdy nie pomija legalnej
% sekwencji i nie ufa wejściowemu przybliżeniu licznika.
%
% Kursor jest strukturą nietrwałą, a NIE podpisanym checkpointem.

if ~(isnumeric(originalLengths) && isvector(originalLengths) && ...
        ~isempty(originalLengths) && all(isreal(originalLengths)) && ...
        all(isfinite(originalLengths)) && ...
        all(originalLengths>0) && ...
        all(fix(originalLengths)==originalLengths) && ...
        all(originalLengths<=flintmax))
    error('Pastafari:AdjointChunk:Lengths', ...
        'Oczekiwano dodatnich dokładnych długości miesięcy.');
end
L=double(originalLengths(:).');
K=numel(L);
% JSON decoders may return a column for a serialized row vector.
% Validate against a normalized column first; never compare a Kx1
% column directly with the 1xK original lengths (implicit expansion).
if ~(isnumeric(remaining) && isvector(remaining) && ...
        numel(remaining)==K && isreal(remaining) && ...
        all(isfinite(remaining(:))) && ...
        all(remaining(:)>=0) && ...
        all(fix(remaining(:))==remaining(:)))
    error('Pastafari:AdjointChunk:Remaining', ...
        'Pozostałe wielokrotności nie pasują do długości.');
end
R=double(remaining(:).');
if any(R>L)
    error('Pastafari:AdjointChunk:Remaining', ...
        'Remaining multiplicity exceeds original month length.');
end
if ~(isnumeric(openedUpTo) && isscalar(openedUpTo) && ...
        isfinite(openedUpTo) && fix(openedUpTo)==openedUpTo && ...
        isnumeric(closedUpTo) && isscalar(closedUpTo) && ...
        isfinite(closedUpTo) && fix(closedUpTo)==closedUpTo && ...
        0<=closedUpTo && closedUpTo<=openedUpTo && openedUpTo<=K)
    error('Pastafari:AdjointChunk:Frontier', ...
        'Stan otwarć i zamknięć musi być dokładny i uporządkowany.');
end
if any(R(1:closedUpTo)~=0) || ...
        any(R(closedUpTo+1:openedUpTo)<=0) || ...
        any(R(closedUpTo+1:openedUpTo)>=L(closedUpTo+1:openedUpTo)) || ...
        any(R(openedUpTo+1:end)~=L(openedUpTo+1:end))
    error('Pastafari:AdjointChunk:Reachability', ...
        'Liczby pozostałych kopii przeczą historii prefiksu.');
end
pastafari.ValidationManager.requireExactIntegerInput(rank1);
rank=pastafari.BigInt.coerce(rank1);
if ~(isnumeric(maxSteps) && isscalar(maxSteps) && ...
        isreal(maxSteps) && isfinite(maxSteps) && ...
        maxSteps>=0 && fix(maxSteps)==maxSteps && ...
        maxSteps<=flintmax)
    error('Pastafari:AdjointChunk:StepLimit', ...
        'Liczba kroków musi być nieujemną dokładną liczbą całkowitą.');
end
N=sum(R);
if ~isfinite(N) || N>flintmax
    error('Pastafari:AdjointChunk:Days', ...
        'Liczba dni nie jest dokładnie reprezentowalna.');
end
steps=min(N,maxSteps);
piece=zeros(1,steps);
known=false;
count=pastafari.BigInt(0);
initialCount=pastafari.BigInt(0);
initialKnown=false;
one=pastafari.BigInt(1);

for position=1:steps
    choices=[];
    for i=closedUpTo+1:K
        n=R(i);
        if n==0 || (n==L(i) && i~=openedUpTo+1) || ...
                (n==1 && i~=closedUpTo+1)
            continue
        end
        choices(end+1)=i; %#ok<AGROW>
    end
    if isempty(choices)
        error('Pastafari:AdjointChunk:DeadEnd', ...
            'Poprawny niekońcowy stan musi mieć legalne wyjście.');
    end
    if numel(choices)==1
        % Nie ma rozdzielania rang. Gdy count jest już znany,
        % pozostaje niezmieniony.
        selected=choices(1);
    else
        blocks=cell(1,K);
        if openedUpTo<K-1
            % Jedno uruchomienie oblicza RAZEM rodzica i bloki.
            [blocks,actual]= ...
                pastafari.countWholeWeavingNextLetterBlocksAdjoint( ...
                    R,openedUpTo,closedUpTo);
        else
            if known
                actual=count;
            else
                actual=pastafari.countWholeWeavingSuffixByEndpoints( ...
                    R,openedUpTo,closedUpTo);
            end
            if openedUpTo==K
                blocks=pastafari.allOpenedWholeWeaveChildCountsCommonDenominator( ...
                    R,closedUpTo,actual);
            else
                % Ostatni miesiąc jeszcze nieotwarty. Dokładna
                % faktoryzacja jest dostępna dla każdego dziecka.
                remainder=actual;
                for z=1:numel(choices)
                    j=choices(z);
                    if z==numel(choices)
                        block=remainder;
                    else
                        child=R;
                        child(j)=child(j)-1;
                        openChild=openedUpTo+double(R(j)==L(j));
                        closeChild=closedUpTo+double(R(j)==1);
                        block=pastafari.countWholeWeavingSuffixByEndpoints( ...
                            child,openChild,closeChild);
                    end
                    blocks{j}=block;
                    if block<one || block>remainder
                        error('Pastafari:AdjointChunk:Block', ...
                            'Niedodatni lub nadmierny blok dokładny.');
                    end
                    remainder=remainder-block;
                end
                if remainder~=pastafari.BigInt(0)
                    error('Pastafari:AdjointChunk:Partition', ...
                        'Bloki nie tworzą pełnego podziału rodzica.');
                end
            end
        end
        if known && actual~=count
            error('Pastafari:AdjointChunk:CountMismatch', ...
                'Wspólny licznik przeczy zachowanemu licznikowi.');
        end
        if ~initialKnown
            % Wymuszony prefiks jest bijekcją: to dokładna liczność
            % PIERWOTNEGO wejściowego stanu przed tym fragmentem.
            initialCount=actual;
            initialKnown=true;
        end
        count=actual;
        known=true;
        if rank<one || rank>count
            error('Pastafari:AdjointChunk:Rank', ...
                'Ranga poza przedziałem dokładnej liczby słów.');
        end
        selected=0;
        rest=count;
        for j=choices
            block=blocks{j};
            if isempty(block) || block<one || block>rest
                error('Pastafari:AdjointChunk:Block', ...
                    'Nieprawidłowy dokładny blok leksykograficzny.');
            end
            rest=rest-block;
            if rank>block
                rank=rank-block;
            else
                selected=j;
                count=block;
                break
            end
        end
        if selected==0
            error('Pastafari:AdjointChunk:Unrank', ...
                'Ranga nie wskazuje żadnej legalnej litery.');
        end
    end
    n=R(selected);
    R(selected)=n-1;
    openedUpTo=openedUpTo+double(n==L(selected));
    closedUpTo=closedUpTo+double(n==1);
    piece(position)=selected;
end

% Gdy zadany fragment kończy się przed pierwszym rozgałęzieniem,
% oblicz dokładną liczność dopiero raz, na równoważnym stanie
% po wszystkich wymuszonych literach. Nie zwracaj niezweryfikowanego
% kursora, nawet gdy limit kroków jest zerowy.
if ~known
    if openedUpTo>=K-1
        count=pastafari.countWholeWeavingSuffixByEndpoints( ...
            R,openedUpTo,closedUpTo);
    else
        count=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
            R,openedUpTo,closedUpTo);
    end
end
if ~initialKnown
    % Gdy nie było rozgałęzienia, cały fragment był wymuszony.
    % Liczność po nim jest identyczna z wejściową licznością.
    initialCount=count;
    initialKnown=true;
end
if rank<one || rank>count
    error('Pastafari:AdjointChunk:Rank', ...
        'Ranga poza przedziałem liczby wszystkich słów.');
end
done=all(R==0);
if done && (openedUpTo~=K || closedUpTo~=K || ...
        count~=one || rank~=one)
    error('Pastafari:AdjointChunk:Terminal', ...
        'Dokładnie jeden pusty sufiks musi kończyć poprawne słowo.');
end
cursor=struct('remaining',R, ...
    'openedUpTo',openedUpTo,'closedUpTo',closedUpTo, ...
    'rank',rank,'count',count,'initialCount',initialCount, ...
    'done',done,'stepsComputed',steps);
end
