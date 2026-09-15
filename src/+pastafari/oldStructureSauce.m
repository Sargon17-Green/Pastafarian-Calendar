function result = oldStructureSauce(cDay, originalTargetDay)
% Historyczna wada Discovery 20.
%
% Struktura roku była zasilana Sauce(cDay, originalTargetDay), mimo że
% jej autorytatywnym targetem powinien być pierwszy dzień danego roku.

pastafari.ValidationManager.requireExactIntegerInput(cDay);
pastafari.ValidationManager.requireExactIntegerInput(originalTargetDay);

result = pastafari.sauceWithCurrentScars(cDay, originalTargetDay);
end
