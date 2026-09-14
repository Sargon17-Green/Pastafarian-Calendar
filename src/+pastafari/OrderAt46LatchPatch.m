classdef OrderAt46LatchPatch < handle
    % PATCH 11: jednokrotny latch order bezpośrednio po drop 46.
    % Latch jest niezależny od LegacyOverwritableOrderMemory i nigdy nie
    % może zostać nadpisany przez późniejsze post-stirs.
    properties (SetAccess = private)
        latchedOrder
        captureCount
    end

    methods
        function obj = OrderAt46LatchPatch()
            obj.latchedOrder = [];
            obj.captureCount = 0;
        end

        function captureOnce(obj, order)
            if obj.captureCount ~= 0
                error('Pastafari:OrderLatch:AlreadyCaptured', ...
                    'orderAt46Latch może zostać zapisany dokładnie raz.');
            end
            if ~isnumeric(order) || ~isvector(order) || numel(order) ~= 6 || ...
                    ~isequal(sort(order), 1:6)
                error('Pastafari:OrderLatch:Order', ...
                    'orderAt46Latch wymaga permutacji bowl IDs 1..6.');
            end

            % Jawny clone semantyczny: latch ma własny snapshot order 46.
            obj.latchedOrder = reshape(order, 1, 6);
            obj.captureCount = 1;
        end

        function order = queryOrder(obj)
            if obj.captureCount ~= 1 || isempty(obj.latchedOrder)
                error('Pastafari:OrderLatch:Empty', ...
                    'orderAt46Latch nie został jeszcze zapisany.');
            end
            order = obj.latchedOrder;
        end
    end
end
