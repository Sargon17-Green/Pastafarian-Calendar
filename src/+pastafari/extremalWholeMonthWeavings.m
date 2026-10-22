function [lexFirst, lexLast] = extremalWholeMonthWeavings(monthLengths)
% Eksperyment: pełne skrajne sploty leksykograficzne bez ogromnego DAG.
% Nie zmienia produkcji i NIE zastępuje dowolnego rank/unrank.
%
% Każda legalna lokalnie decyzja ma przynajmniej jedno dokończenie:
% po wybraniu litery można zamykać miesiące w porządku rosnącym,
% otwierając kolejny tylko zgodnie z porządkiem i nigdy nie kończąc
% miesiąca przed poprzednim. Każdy legalny prefiks można zatem
% dokończyć. Najmniejsza/największa legalna kolejna litera daje
% dokładnie pierwsze/ostatnie słowo leksykograficzne.
%
% Słowa mają WSZYSTKIE dni, bez przybliżania i bez odrzucania
% trudnych stanów. Ta metoda dotyczy wyłącznie dwóch skrajnych rang.

if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
        ~isempty(monthLengths) && all(isreal(monthLengths)) && ...
        all(isfinite(monthLengths)) && ...
        all(fix(monthLengths)==monthLengths) && ...
        all(monthLengths>0) && all(monthLengths<=flintmax))
    error('Pastafari:ExtremalWeave:Lengths', ...
        'Oczekiwano niepustego wektora dokładnych dodatnich długości.');
end
L=double(monthLengths(:).');
N=sum(L);
if ~isfinite(N) || N>flintmax
    error('Pastafari:ExtremalWeave:Days', ...
        'Łączna liczba dni musi być reprezentowalna dokładnie.');
end
lexFirst=buildGreedy(L,N,false);
lexLast=buildGreedy(L,N,true);
end

function word=buildGreedy(L,N,chooseLargest)
K=numel(L);
remaining=L;
opened=0;
closed=0;
word=zeros(1,N);

for position=1:N
    selected=0;
    if chooseLargest
        indices=K:-1:1;
    else
        indices=1:K;
    end
    for i=indices
        n=remaining(i);
        if n==0 || (n==L(i) && i~=opened+1) || ...
                (n==1 && i~=closed+1)
            continue
        end
        selected=i;
        break
    end
    if selected==0
        error('Pastafari:ExtremalWeave:DeadEnd', ...
            'Nie ma legalnej kolejnej litery w poprawnym prefiksie.');
    end
    n=remaining(selected);
    remaining(selected)=n-1;
    if n==L(selected)
        opened=opened+1;
    end
    if n==1
        closed=closed+1;
    end
    word(position)=selected;
end
if any(remaining~=0) || opened~=K || closed~=K
    error('Pastafari:ExtremalWeave:Terminal', ...
        'Nie otrzymano kompletnego legalnego splotu.');
end
end
