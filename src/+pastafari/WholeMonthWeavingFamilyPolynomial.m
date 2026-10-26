classdef WholeMonthWeavingFamilyPolynomial < handle
    % EXPERIMENTAL drop-in candidate for WholeMonthWeavingFamily.
    % Exact language, one-based lexical rank, unchanged production oracle.
    % Unlike the historic family, never enumerates remaining-vector states.
    % The constructor caches ONE exact polynomial-state completion count.
    % itemAt1 uses the separately verified streamed adjoint suffix unrank.
    properties (SetAccess=private)
        monthLengths
        monthCount
        totalDays
    end
    properties (Access=private)
        exactCount
    end
    methods
        function obj=WholeMonthWeavingFamilyPolynomial(monthLengths)
            if ~(isnumeric(monthLengths) && isvector(monthLengths) && ...
                    ~isempty(monthLengths) && isreal(monthLengths) && ...
                    all(isfinite(monthLengths(:))) && ...
                    all(fix(monthLengths(:))==monthLengths(:)) && ...
                    all(monthLengths(:)>0) && ...
                    all(monthLengths(:)<=flintmax))
                error('Pastafari:PolynomialFamily:Lengths', ...
                    'Original month lengths must be positive exact integers.');
            end
            obj.monthLengths=double(monthLengths(:).');
            obj.monthCount=numel(obj.monthLengths);
            obj.totalDays=sum(obj.monthLengths);
            if ~isfinite(obj.totalDays) || obj.totalDays>flintmax
                error('Pastafari:PolynomialFamily:Days', ...
                    'Total days must be an exact representable integer.');
            end
            obj.exactCount=pastafari.countWholeWeavingSuffixByFirstEndpoint( ...
                obj.monthLengths,0,0);
            if obj.exactCount<pastafari.BigInt(1)
                error('Pastafari:PolynomialFamily:Empty', ...
                    'A legal whole-month family has at least one weaving.');
            end
        end

        function total=count(obj)
            total=obj.exactCount;
        end

        function [prefix,cursor]=prefixAt1(obj,rank1,maxSteps)
            pastafari.ValidationManager.requireExactIntegerInput(rank1);
            rank=pastafari.BigInt.coerce(rank1);
            if rank<pastafari.BigInt(1) || rank>obj.exactCount
                error('Pastafari:PolynomialFamily:Rank', ...
                    'Rank must be in exact one-based family cardinality.');
            end
            [prefix,cursor]=pastafari.unrankGeneralWeaveSuffixChunkAdjoint( ...
                obj.monthLengths,obj.monthLengths,0,0,rank,maxSteps);
            if cursor.initialCount~=obj.exactCount
                error('Pastafari:PolynomialFamily:CountDisagreement', ...
                    'Adjoint parent count contradicts cached exact total.');
            end
        end

        function weaving=itemAt1(obj,rank1)
            pastafari.ValidationManager.requireExactIntegerInput(rank1);
            rank=pastafari.BigInt.coerce(rank1);
            one=pastafari.BigInt(1);
            if rank<one || rank>obj.exactCount
                error('Pastafari:PolynomialFamily:Rank', ...
                    'Rank must be in exact one-based family cardinality.');
            end
            % Exact legal near-edge ranks admit a strictly bounded
            % complete-word algorithm. Unlike the generic interior rank,
            % it never constructs the exponential remaining-vector DAG
            % and never recounts any 4244-day suffix.
            nearLimit=pastafari.BigInt(128);
            if rank<=nearLimit
                distanceBig=rank-one;
                distance=distanceBig.toDoubleExact();
                [weaving,~]=pastafari.unrankWholeWeavingNearEdge( ...
                    obj.monthLengths,distance,'first');
                obj.verifyWord(weaving);
                return
            elseif obj.exactCount-rank<nearLimit
                distanceBig=obj.exactCount-rank;
                distance=distanceBig.toDoubleExact();
                [weaving,~]=pastafari.unrankWholeWeavingNearEdge( ...
                    obj.monthLengths,distance,'last');
                obj.verifyWord(weaving);
                return
            end
            [weaving,cursor]=obj.prefixAt1(rank,obj.totalDays);
            if ~cursor.done || numel(weaving)~=obj.totalDays || ...
                    cursor.rank~=pastafari.BigInt(1) || ...
                    cursor.count~=pastafari.BigInt(1) || ...
                    any(cursor.remaining~=0) || ...
                    cursor.openedUpTo~=obj.monthCount || ...
                    cursor.closedUpTo~=obj.monthCount
                error('Pastafari:PolynomialFamily:Terminal', ...
                    'Lexical unrank must terminate at one exact word.');
            end
        end

        function words=edgeWindowAt1(obj,maxOffset,edge)
            % EXPERIMENTAL: emit all complete legal edge ranks 0..d
            % in ONE traversal. Rows: first -> ranks 1..d+1;
            % last -> ranks F..F-d, where F=obj.count().
            % No truncated BigInt ranks, partial words, or DP DAG.
            if ~(isnumeric(maxOffset) && isscalar(maxOffset) && ...
                    isreal(maxOffset) && isfinite(maxOffset) && ...
                    fix(maxOffset)==maxOffset && ...
                    maxOffset>=0 && maxOffset<=127)
                error('Pastafari:PolynomialFamily:EdgeWindowLimit', ...
                    'The exact edge-window offset must be in 0..127.');
            end
            if ~(ischar(edge) && isrow(edge) && ...
                    (strcmp(edge,'first') || strcmp(edge,'last')))
                error('Pastafari:PolynomialFamily:EdgeWindowSide', ...
                    'Edge must be first or last.');
            end
            if pastafari.BigInt(maxOffset)>=obj.exactCount
                error('Pastafari:PolynomialFamily:EdgeWindowRange', ...
                    'The requested window exceeds the exact rank count.');
            end
            words=zeros(maxOffset+1,obj.totalDays);
            [current,~]=pastafari.unrankWholeWeavingNearEdge( ...
                obj.monthLengths,0,edge);
            obj.verifyWord(current);
            words(1,:)=current;
            if strcmp(edge,'first')
                direction='next';
            else
                direction='previous';
            end
            for offset=1:maxOffset
                [next,exists]=pastafari.adjacentWholeMonthWeaving( ...
                    current,obj.monthLengths,direction);
                if ~exists
                    error('Pastafari:PolynomialFamily:EdgeWindowPremature', ...
                        'Exact rank count contradicts lexical neighbor.');
                end
                obj.verifyWord(next);
                words(offset+1,:)=next;
                current=next;
            end
        end

        function verifyWord(obj,word)
            % Independent linear terminal invariant guard even for
            % accelerated extremal and nearest-extremal rank routes.
            if ~(isnumeric(word) && isrow(word) && ...
                    numel(word)==obj.totalDays && ...
                    all(isfinite(word)) && all(fix(word)==word) && ...
                    all(word>=1) && all(word<=obj.monthCount))
                error('Pastafari:PolynomialFamily:Terminal', ...
                    'Near-edge result must be a complete exact month word.');
            end
            first=zeros(1,obj.monthCount);
            last=zeros(1,obj.monthCount);
            for month=1:obj.monthCount
                positions=find(word==month);
                if numel(positions)~=obj.monthLengths(month)
                    error('Pastafari:PolynomialFamily:Terminal', ...
                        'Month occurrence multiplicity is incorrect.');
                end
                first(month)=positions(1);
                last(month)=positions(end);
            end
            if any(diff(first)<=0) || any(diff(last)<=0)
                error('Pastafari:PolynomialFamily:Terminal', ...
                    'Month opening or closure order is invalid.');
            end
        end
    end
end
