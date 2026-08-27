classdef BigInt
    % Dokładna liczba całkowita o dowolnej precyzji, zbudowana wyłącznie w MATLAB-ie.
    properties (SetAccess = private)
        signValue
        limbs
    end
    properties (Constant, Access = private)
        BASE = 10000000
        BASE_DIGITS = 7
    end
    methods
        function obj = BigInt(value)
            if nargin == 0
                obj.signValue = 0;
                obj.limbs = 0;
                return
            end
            if isa(value, 'pastafari.BigInt')
                obj = value;
                return
            end
            if ischar(value) || (isstring(value) && isscalar(value))
                s = char(value);
                [sgn, lm] = pastafari.BigInt.parseDecimal(s);
                obj.signValue = sgn;
                obj.limbs = lm;
                obj = obj.normalize();
                return
            end
            if isnumeric(value) && isscalar(value) && isreal(value) && isfinite(value) && fix(value) == value
                if abs(double(value)) > flintmax
                    error('Pastafari:BigInt:UnsafeNumericInput', ...
                        'Wartość numeryczna przekracza zakres dokładnych liczb całkowitych MATLAB-a; użyj napisu dziesiętnego.');
                end
                [sgn, lm] = pastafari.BigInt.parseDecimal(sprintf('%.0f', double(value)));
                obj.signValue = sgn;
                obj.limbs = lm;
                obj = obj.normalize();
                return
            end
            error('Pastafari:BigInt:InvalidInput', 'Nieprawidłowe źródło liczby całkowitej.');
        end

        function s = char(obj)
            if obj.signValue == 0
                s = '0';
                return
            end
            lm = obj.limbs;
            s = sprintf('%d', lm(end));
            for k = numel(lm)-1:-1:1
                s = [s, sprintf('%07d', lm(k))]; %#ok<AGROW>
            end
            if obj.signValue < 0
                s = ['-', s];
            end
        end

        function tf = iszero(obj)
            tf = obj.signValue == 0;
        end

        function tf = isnegative(obj)
            tf = obj.signValue < 0;
        end

        function tf = ispositive(obj)
            tf = obj.signValue > 0;
        end

        function d = toDoubleExact(obj)
            s = char(obj);
            d = str2double(s);
            if ~isfinite(d) || abs(d) > flintmax || pastafari.BigInt(d) ~= obj
                error('Pastafari:BigInt:NotExactlyRepresentable', ...
                    'Liczby nie można dokładnie przedstawić jako typu double.');
            end
        end

        function out = uminus(a)
            out = a;
            out.signValue = -out.signValue;
        end

        function out = abs(a)
            out = a;
            if out.signValue < 0
                out.signValue = 1;
            end
        end

        function out = plus(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            if a.signValue == 0
                out = b;
                return
            end
            if b.signValue == 0
                out = a;
                return
            end
            if a.signValue == b.signValue
                out = pastafari.BigInt.fromParts(a.signValue, pastafari.BigInt.addMagnitude(a.limbs, b.limbs));
                return
            end
            cmp = pastafari.BigInt.compareMagnitude(a.limbs, b.limbs);
            if cmp == 0
                out = pastafari.BigInt(0);
            elseif cmp > 0
                out = pastafari.BigInt.fromParts(a.signValue, pastafari.BigInt.subMagnitude(a.limbs, b.limbs));
            else
                out = pastafari.BigInt.fromParts(b.signValue, pastafari.BigInt.subMagnitude(b.limbs, a.limbs));
            end
        end

        function out = minus(a, b)
            out = plus(a, -pastafari.BigInt.coerce(b));
        end

        function out = mtimes(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            if a.signValue == 0 || b.signValue == 0
                out = pastafari.BigInt(0);
                return
            end
            lm = pastafari.BigInt.mulMagnitude(a.limbs, b.limbs);
            out = pastafari.BigInt.fromParts(a.signValue * b.signValue, lm);
        end

        function tf = eq(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            tf = a.signValue == b.signValue && isequal(a.limbs, b.limbs);
        end

        function tf = ne(a, b)
            tf = ~(a == b);
        end

        function tf = lt(a, b)
            tf = pastafari.BigInt.compare(a, b) < 0;
        end

        function tf = le(a, b)
            tf = pastafari.BigInt.compare(a, b) <= 0;
        end

        function tf = gt(a, b)
            tf = pastafari.BigInt.compare(a, b) > 0;
        end

        function tf = ge(a, b)
            tf = pastafari.BigInt.compare(a, b) >= 0;
        end

        function [q, r] = floorDivMod(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            if b.signValue <= 0
                error('Pastafari:BigInt:BadDivisor', 'Dzielnik musi być dodatnią liczbą całkowitą.');
            end
            if a.signValue == 0
                q = pastafari.BigInt(0);
                r = pastafari.BigInt(0);
                return
            end
            aa = abs(a);
            [qMag, rMag] = pastafari.BigInt.divmodMagnitude(aa.limbs, b.limbs);
            qAbs = pastafari.BigInt.fromParts(1, qMag);
            rAbs = pastafari.BigInt.fromParts(1, rMag);
            if a.signValue > 0
                q = qAbs;
                r = rAbs;
                return
            end
            if rAbs.iszero()
                q = -qAbs;
                r = rAbs;
            else
                q = -(qAbs + 1);
                r = b - rAbs;
            end
        end

        function q = floorDiv(a, b)
            [q, ~] = floorDivMod(a, b);
        end

        function r = regularMod(a, b)
            [~, r] = floorDivMod(a, b);
        end

        function out = square(a)
            out = a * a;
        end

        function out = powNonnegative(a, exponent)
            if ~(isnumeric(exponent) && isscalar(exponent) && exponent >= 0 && fix(exponent) == exponent)
                error('Pastafari:BigInt:BadExponent', 'Wykładnik musi być nieujemną małą liczbą całkowitą.');
            end
            base = a;
            out = pastafari.BigInt(1);
            e = double(exponent);
            while e > 0
                if mod(e, 2) == 1
                    out = out * base;
                end
                e = floor(e / 2);
                if e > 0
                    base = base * base;
                end
            end
        end
    end

    methods (Static)
        function obj = coerce(value)
            if isa(value, 'pastafari.BigInt')
                obj = value;
            else
                obj = pastafari.BigInt(value);
            end
        end
    end

    methods (Access = private)
        function obj = normalize(obj)
            lm = obj.limbs;
            while numel(lm) > 1 && lm(end) == 0
                lm(end) = [];
            end
            if numel(lm) == 1 && lm(1) == 0
                obj.signValue = 0;
                obj.limbs = 0;
            else
                obj.limbs = lm;
                if obj.signValue == 0
                    obj.signValue = 1;
                end
            end
        end
    end

    methods (Static, Access = private)
        function [sgn, lm] = parseDecimal(s)
            s = strtrim(s);
            if isempty(s)
                error('Pastafari:BigInt:InvalidText', 'Pusty napis nie jest liczbą całkowitą.');
            end
            sgn = 1;
            if s(1) == '-'
                sgn = -1;
                s = s(2:end);
            elseif s(1) == '+'
                s = s(2:end);
            end
            if isempty(s) || any(s < '0' | s > '9')
                error('Pastafari:BigInt:InvalidText', 'Napis zawiera znaki inne niż cyfry dziesiętne.');
            end
            firstNonzero = find(s ~= '0', 1, 'first');
            if isempty(firstNonzero)
                sgn = 0;
                lm = 0;
                return
            end
            s = s(firstNonzero:end);
            count = ceil(numel(s) / pastafari.BigInt.BASE_DIGITS);
            lm = zeros(1, count);
            pos = numel(s);
            idx = 1;
            while pos >= 1
                startPos = max(1, pos - pastafari.BigInt.BASE_DIGITS + 1);
                lm(idx) = str2double(s(startPos:pos));
                idx = idx + 1;
                pos = startPos - 1;
            end
        end

        function obj = fromParts(sgn, lm)
            obj = pastafari.BigInt();
            obj.signValue = sgn;
            obj.limbs = lm;
            obj = obj.normalize();
        end

        function c = compare(a, b)
            a = pastafari.BigInt.coerce(a);
            b = pastafari.BigInt.coerce(b);
            if a.signValue < b.signValue
                c = -1;
                return
            elseif a.signValue > b.signValue
                c = 1;
                return
            end
            if a.signValue == 0
                c = 0;
                return
            end
            c = pastafari.BigInt.compareMagnitude(a.limbs, b.limbs);
            if a.signValue < 0
                c = -c;
            end
        end

        function c = compareMagnitude(a, b)
            a = pastafari.BigInt.trimMagnitude(a);
            b = pastafari.BigInt.trimMagnitude(b);
            if numel(a) < numel(b)
                c = -1;
                return
            elseif numel(a) > numel(b)
                c = 1;
                return
            end
            c = 0;
            for k = numel(a):-1:1
                if a(k) < b(k)
                    c = -1;
                    return
                elseif a(k) > b(k)
                    c = 1;
                    return
                end
            end
        end

        function out = addMagnitude(a, b)
            n = max(numel(a), numel(b));
            out = zeros(1, n + 1);
            carry = 0;
            for k = 1:n
                av = 0; bv = 0;
                if k <= numel(a), av = a(k); end
                if k <= numel(b), bv = b(k); end
                cur = av + bv + carry;
                if cur >= pastafari.BigInt.BASE
                    cur = cur - pastafari.BigInt.BASE;
                    carry = 1;
                else
                    carry = 0;
                end
                out(k) = cur;
            end
            out(n + 1) = carry;
            out = pastafari.BigInt.trimMagnitude(out);
        end

        function out = subMagnitude(a, b)
            % Wymagane |a| >= |b|.
            out = zeros(1, numel(a));
            borrow = 0;
            for k = 1:numel(a)
                bv = 0;
                if k <= numel(b), bv = b(k); end
                cur = a(k) - bv - borrow;
                if cur < 0
                    cur = cur + pastafari.BigInt.BASE;
                    borrow = 1;
                else
                    borrow = 0;
                end
                out(k) = cur;
            end
            if borrow ~= 0
                error('Pastafari:BigInt:InternalSubtraction', 'Wewnętrzny błąd odejmowania modułów.');
            end
            out = pastafari.BigInt.trimMagnitude(out);
        end

        function out = mulMagnitude(a, b)
            a = pastafari.BigInt.trimMagnitude(a);
            b = pastafari.BigInt.trimMagnitude(b);
            if (numel(a) == 1 && a(1) == 0) || (numel(b) == 1 && b(1) == 0)
                out = 0;
                return
            end
            out = zeros(1, numel(a) + numel(b) + 1);
            for i = 1:numel(a)
                carry = 0;
                for j = 1:numel(b)
                    k = i + j - 1;
                    cur = out(k) + a(i) * b(j) + carry;
                    out(k) = mod(cur, pastafari.BigInt.BASE);
                    carry = floor(cur / pastafari.BigInt.BASE);
                end
                k = i + numel(b);
                while carry > 0
                    cur = out(k) + carry;
                    out(k) = mod(cur, pastafari.BigInt.BASE);
                    carry = floor(cur / pastafari.BigInt.BASE);
                    k = k + 1;
                end
            end
            out = pastafari.BigInt.trimMagnitude(out);
        end

        function out = mulMagnitudeSmall(a, small)
            if small == 0
                out = 0;
                return
            end
            out = zeros(1, numel(a) + 2);
            carry = 0;
            for i = 1:numel(a)
                cur = a(i) * small + carry;
                out(i) = mod(cur, pastafari.BigInt.BASE);
                carry = floor(cur / pastafari.BigInt.BASE);
            end
            idx = numel(a) + 1;
            while carry > 0
                out(idx) = mod(carry, pastafari.BigInt.BASE);
                carry = floor(carry / pastafari.BigInt.BASE);
                idx = idx + 1;
            end
            out = pastafari.BigInt.trimMagnitude(out);
        end

        function [q, r] = divmodMagnitude(a, b)
            a = pastafari.BigInt.trimMagnitude(a);
            b = pastafari.BigInt.trimMagnitude(b);
            if numel(b) == 1 && b(1) == 0
                error('Pastafari:BigInt:DivisionByZero', 'Dzielenie przez zero.');
            end
            if pastafari.BigInt.compareMagnitude(a, b) < 0
                q = 0;
                r = a;
                return
            end
            q = zeros(1, numel(a));
            r = 0;
            for pos = numel(a):-1:1
                r = pastafari.BigInt.shiftBaseAdd(r, a(pos));
                lo = 0;
                hi = pastafari.BigInt.BASE - 1;
                best = 0;
                while lo <= hi
                    mid = floor((lo + hi) / 2);
                    probe = pastafari.BigInt.mulMagnitudeSmall(b, mid);
                    cmp = pastafari.BigInt.compareMagnitude(probe, r);
                    if cmp <= 0
                        best = mid;
                        lo = mid + 1;
                    else
                        hi = mid - 1;
                    end
                end
                q(pos) = best;
                if best ~= 0
                    r = pastafari.BigInt.subMagnitude(r, pastafari.BigInt.mulMagnitudeSmall(b, best));
                end
            end
            q = pastafari.BigInt.trimMagnitude(q);
            r = pastafari.BigInt.trimMagnitude(r);
        end

        function out = shiftBaseAdd(a, digit)
            a = pastafari.BigInt.trimMagnitude(a);
            if numel(a) == 1 && a(1) == 0
                out = digit;
            else
                out = [digit, a];
            end
            out = pastafari.BigInt.trimMagnitude(out);
        end

        function lm = trimMagnitude(lm)
            while numel(lm) > 1 && lm(end) == 0
                lm(end) = [];
            end
            if isempty(lm)
                lm = 0;
            end
        end
    end
end
