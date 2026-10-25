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
            [weaving,cursor]=obj.prefixAt1(rank1,obj.totalDays);
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
    end
end
