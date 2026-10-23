function [neighbor, exists] = adjacentWholeMonthWeaving(word, monthLengths, direction)
% Eksperymentalny dokladny nastepnik / poprzednik leksykograficzny.
% Nie oblicza wielkich rang posrednich i NIE zastępuje produkcyjnego
% rank/unrank. Zadna legalna permutacja nie jest pomijana.
%
% Przy przegladaniu pozycji od konca cofamy stan prefiksu (liczniki
% pozostalych kopii, ostatni otwarty i ostatni zamkniety miesiac).
% W pierwszej pozycji, w ktorej mozna legalnie zmienic litere w
% zadanym kierunku, wybieramy najblizsza taka litere, a nastepnie
% dopelniamy reszte leksykograficznie najmniejszym/najwiekszym
% legalnym sufiksem. Kazda lokalnie legalna decyzja jest
% przedluzalna do pelnego slowa (zamykanie miesiecy po kolei).
%
% Koszt O(K*N), pamiec O(K+N), dla N=sum(monthLengths).
% Kompletne slowo musi juz byc podane i jest walidowane przed
% jakakolwiek proba znalezienia sasiedniej rangi.

if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
        ~isempty(monthLengths) && isreal(monthLengths) && ...
        all(isfinite(monthLengths)) && ...
        all(fix(monthLengths)==monthLengths) && ...
        all(monthLengths>0) && all(monthLengths<=flintmax))
    error('Pastafari:AdjacentWeave:Lengths', ...
        'Month lengths must be nonempty positive exact integers.');
end
L=double(monthLengths(:).');
K=numel(L);
N=sum(L);
if ~isfinite(N) || N>flintmax
    error('Pastafari:AdjacentWeave:Days', ...
        'Total day count must be exactly representable.');
end
if ~(isnumeric(word) && isvector(word) && isreal(word) && ...
        numel(word)==N && all(isfinite(word)) && ...
        all(fix(word)==word) && all(word>=1) && all(word<=K))
    error('Pastafari:AdjacentWeave:Word', ...
        'Input must be a complete exact integer month-ID weaving.');
end
word=double(word(:).');
if ~(ischar(direction) && isrow(direction) && ...
        (strcmp(direction,'next') || strcmp(direction,'previous')))
    error('Pastafari:AdjacentWeave:Direction', ...
        'Direction must be next or previous.');
end

% Niezalezna walidacja wszystkich pozycji pierwszych/ostatnich.
first=zeros(1,K);
last=zeros(1,K);
for j=1:K
    positions=find(word==j);
    if numel(positions)~=L(j)
        error('Pastafari:AdjacentWeave:Multiplicity', ...
            'Month occurrence multiplicity does not match the source.');
    end
    first(j)=positions(1);
    last(j)=positions(end);
end
if any(diff(first)<=0) || any(diff(last)<=0)
    error('Pastafari:AdjacentWeave:Ordering', ...
        'First and last occurrence orders must both be increasing.');
end

forward=strcmp(direction,'next');
R=zeros(1,K);
opened=K;
closed=K;
neighbor=[];
exists=false;

% Cofamy prefiks o jedna litere przy kazdej iteracji.
for pivot=N:-1:1
    letter=word(pivot);
    R(letter)=R(letter)+1;
    if R(letter)==1
        closed=closed-1;
    end
    if R(letter)==L(letter)
        opened=opened-1;
    end
    if forward
        candidates=letter+1:K;
    else
        candidates=letter-1:-1:1;
    end
    for i=candidates
        n=R(i);
        if n==0 || (n==L(i) && i~=opened+1) || ...
                (n==1 && i~=closed+1)
            continue
        end
        result=zeros(1,N);
        if pivot>1
            result(1:pivot-1)=word(1:pivot-1);
        end
        result(pivot)=i;
        remaining=R;
        remaining(i)=n-1;
        o=opened+double(n==L(i));
        c=closed+double(n==1);

        % Najmniejszy / najwiekszy mozliwy sufiks.
        for pos=pivot+1:N
            chosen=0;
            if forward
                order=1:K;
            else
                order=K:-1:1;
            end
            for j=order
                x=remaining(j);
                if x==0 || (x==L(j) && j~=o+1) || ...
                        (x==1 && j~=c+1)
                    continue
                end
                chosen=j;
                break
            end
            if chosen==0
                error('Pastafari:AdjacentWeave:DeadEnd', ...
                    'A valid lexical prefix must admit a full completion.');
            end
            x=remaining(chosen);
            remaining(chosen)=x-1;
            o=o+double(x==L(chosen));
            c=c+double(x==1);
            result(pos)=chosen;
        end
        if any(remaining~=0) || o~=K || c~=K
            error('Pastafari:AdjacentWeave:Terminal', ...
                'A full legal neighbor must close every month.');
        end
        neighbor=result;
        exists=true;
        return
    end
end
end
