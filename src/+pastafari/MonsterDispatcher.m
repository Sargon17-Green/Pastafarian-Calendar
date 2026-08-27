classdef MonsterDispatcher
    % Neutralny dyspozytor bazowy; świadomie nie zawiera trasowania żadnej przyszłej łaty.
    methods (Static)
        function ctx = dispatch(ctx, handler)
            pastafari.ValidationManager.requireContext(ctx);
            if ~isa(handler, 'function_handle')
                error('Pastafari:Dispatcher:InvalidHandler', 'Procedura obsługi musi być uchwytem funkcji MATLAB-a.');
            end
            ctx.branchTrace{end + 1} = 'BASE_DISPATCH';
            ctx = handler(ctx);
            pastafari.ValidationManager.requireContext(ctx);
        end
    end
end
