classdef LegacyMonthWeavingAdapter
    % Adapter utrzymujący historyczny daily chooser jako realny ghost.
    methods (Static)
        function [ctx, stream, ghost, proposals, remaining] = ...
                call(ctx, structureSauce, monthLengths)
            pastafari.ValidationManager.requireContext(ctx);

            stream = pastafari.buildMonthWeavingAnswerRing(structureSauce);
            [ghost, proposals, remaining] = ...
                pastafari.legacyChooseEachDaySeparately( ...
                    stream, monthLengths);
        end
    end
end
