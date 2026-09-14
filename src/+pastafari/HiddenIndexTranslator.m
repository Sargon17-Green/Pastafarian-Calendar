classdef HiddenIndexTranslator
    % PATCH 05: logiczne hidden k odczytuje fizyczny slot 8-k.
    % Fizycznego magazynu hidden7..hidden1 nie wolno odwracać ani przepisywać.
    methods (Static)
        function slot = physicalSlot(hiddenIndex)
            if ~(isnumeric(hiddenIndex) && isscalar(hiddenIndex) && ...
                    isfinite(hiddenIndex) && fix(hiddenIndex) == hiddenIndex && ...
                    hiddenIndex >= 1 && hiddenIndex <= 7)
                error('Pastafari:Hidden:TranslatedIndex', ...
                    'Logiczny indeks hidden musi należeć do zakresu 1..7.');
            end
            slot = 8 - hiddenIndex;
        end

        function value = read(storage, hiddenIndex)
            if ~iscell(storage) || numel(storage) ~= 7
                error('Pastafari:Hidden:TranslatedStorageShape', ...
                    'Magazyn hidden musi zawierać dokładnie siedem pól.');
            end
            slot = pastafari.HiddenIndexTranslator.physicalSlot(hiddenIndex);
            value = storage{slot};
        end
    end
end
