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
        actionCount
        targetCount
        legacyDistanceValue
        distanceCandidate
        connectionCount
        directionCount
        legacyStoneTable
        legacySecondStoneRow
        stoneTableCandidate
        hiddenBackward
        legacyHiddenLogicalCandidate
        hiddenLogicalCandidate
        legacyPriorRequestedSlots
        legacyPriorMissingMatrix
        legacyVisibleDrops
        visibleDropsCandidate
        preGrindVisibleDrops
        legacyGrindRequestedIndices
        legacyGrindResolvedIndices
        legacyGrindVisibleDrops
        grindVisibleCandidate
        permutationInput
        legacyPermutationRank0
        legacyPermutationOrder
        permutationRank1Candidate
        permutationDetourRank0
        permutationOrderCandidate
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
            obj.actionCount = [];
            obj.targetCount = [];
            obj.legacyDistanceValue = [];
            obj.distanceCandidate = [];
            obj.connectionCount = [];
            obj.directionCount = [];
            obj.legacyStoneTable = [];
            obj.legacySecondStoneRow = [];
            obj.stoneTableCandidate = [];
            obj.hiddenBackward = [];
            obj.legacyHiddenLogicalCandidate = [];
            obj.hiddenLogicalCandidate = [];
            obj.legacyPriorRequestedSlots = [];
            obj.legacyPriorMissingMatrix = [];
            obj.legacyVisibleDrops = [];
            obj.visibleDropsCandidate = [];
            obj.preGrindVisibleDrops = [];
            obj.legacyGrindRequestedIndices = [];
            obj.legacyGrindResolvedIndices = [];
            obj.legacyGrindVisibleDrops = [];
            obj.grindVisibleCandidate = [];
            obj.permutationInput = [];
            obj.legacyPermutationRank0 = [];
            obj.legacyPermutationOrder = [];
            obj.permutationRank1Candidate = [];
            obj.permutationDetourRank0 = [];
            obj.permutationOrderCandidate = [];
        end
    end
end
