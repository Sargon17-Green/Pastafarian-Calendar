function stream = buildMonthWeavingAnswerRing(structureSauce)
% Answer ring używany do month weaving: bowl 4 / seal 32.

if ~isstruct(structureSauce) || ...
        ~isfield(structureSauce, 'bowls') || ...
        ~isfield(structureSauce, 'orderAt46Latch')
    error('Pastafari:MonthWeaving:StructureSauceShape', ...
        'Month weaving wymaga bowls i orderAt46Latch.');
end

if ~iscell(structureSauce.bowls) || numel(structureSauce.bowls) ~= 6
    error('Pastafari:MonthWeaving:StructureSauceBowls', ...
        'Structure sauce musi zawierać sześć bowls.');
end

order = structureSauce.orderAt46Latch;
if ~(isnumeric(order) && isvector(order) && numel(order) == 6 && ...
        isequal(sort(order(:).'), 1:6))
    error('Pastafari:MonthWeaving:StructureSauceOrder', ...
        'orderAt46Latch musi być permutacją 1..6.');
end

nextBowlId = pastafari.LatchedSuccessorPatch.apply(order, 4);
stream = pastafari.AnswerRingStreamFactory.fromSauce( ...
    structureSauce.bowls, 4, nextBowlId, 32);
end
