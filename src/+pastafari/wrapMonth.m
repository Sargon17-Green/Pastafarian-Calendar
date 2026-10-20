function wrapped = wrapMonth(monthId, monthCount)
% Historyczne pomocnicze zawijanie indeksu miesiąca do 1..monthCount.

pastafari.ValidationManager.requireExactIntegerInput(monthId);
pastafari.ValidationManager.requireExactIntegerInput(monthCount);

id = pastafari.BigInt.coerce(monthId);
count = pastafari.BigInt.coerce(monthCount);

if count < pastafari.BigInt(1)
    error('Pastafari:MonthWeaving:WrapCount', ...
        'monthCount musi być dodatni.');
end

offset = id - pastafari.BigInt(1);
zeroBased = offset.regularMod(count);
wrappedExact = zeroBased + pastafari.BigInt(1);
wrapped = wrappedExact.toDoubleExact();
end
