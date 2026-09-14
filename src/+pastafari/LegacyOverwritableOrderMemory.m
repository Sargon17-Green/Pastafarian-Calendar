classdef LegacyOverwritableOrderMemory < handle
    % Historyczna pamięć Discovery 11: dokładnie jedno nadpisywalne pole order.
    % Drop orders i post-stir orders zapisują do tego samego miejsca.
    % Nie istnieje jeszcze osobny orderAt46Latch.
    properties (SetAccess = private)
        currentOrder
        writeCount
        lastSource
    end

    methods
        function obj = LegacyOverwritableOrderMemory()
            obj.currentOrder = [];
            obj.writeCount = 0;
            obj.lastSource = '';
        end

        function write(obj, order, source)
            if ~isnumeric(order) || ~isvector(order) || numel(order) ~= 6 || ...
                    ~isequal(sort(order), 1:6)
                error('Pastafari:OrderMemory:Order', ...
                    'Historyczna pamięć wymaga permutacji bowl IDs 1..6.');
            end
            if ~(ischar(source) || (isstring(source) && isscalar(source)))
                error('Pastafari:OrderMemory:Source', ...
                    'Źródło zapisu order musi być pojedynczym tekstem.');
            end

            obj.currentOrder = reshape(order, 1, 6);
            obj.writeCount = obj.writeCount + 1;
            obj.lastSource = char(source);
        end

        function order = queryOrder(obj)
            if isempty(obj.currentOrder)
                error('Pastafari:OrderMemory:Empty', ...
                    'Historyczna pamięć order nie została jeszcze zapisana.');
            end
            order = obj.currentOrder;
        end
    end
end
