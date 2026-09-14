classdef MonsterContext < handle
    % Kontekst jednego wywołania, rozbudowywany historycznie wraz z kolejnymi etapami.
    properties
        calculationDay
        targetDay
        phase
        subPhase
        mode
        status
        branchTrace
        metrics
        logs
        diagnostics
        lastError
        legacyRemainderInput
        legacyRemainderValue
        saveCandidate
        dayTagInput
        legacyDayTagValue
        dayTagCandidate
    end
    methods
        function obj = MonsterContext(calculationDay, targetDay)
            obj.calculationDay = calculationDay;
            obj.targetDay = targetDay;
            obj.phase = 'BOOTSTRAP_ENTRY';
            obj.subPhase = 0;
            obj.mode = 'BOOTSTRAP_NEUTRAL';
            obj.status = 'NEW';
            obj.branchTrace = {};
            obj.metrics = struct();
            obj.logs = {};
            obj.diagnostics = {};
            obj.lastError = [];
            obj.legacyRemainderInput = [];
            obj.legacyRemainderValue = [];
            obj.saveCandidate = [];
            obj.dayTagInput = [];
            obj.legacyDayTagValue = [];
            obj.dayTagCandidate = [];
        end
    end
end
