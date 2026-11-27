>>SOURCE FORMAT FREE
identification division.
program-id. CALENDAR-YEAR-CANDIDATES.
data division.
local-storage section.
01 ix binary-long signed.
01 jx binary-long signed.
01 span-days binary-long signed.
01 slot-no binary-long signed.
01 delta-days binary-long signed.
01 first-gate binary-long signed.
01 last-gate binary-long signed.
01 lookup-table.
   02 gate-index binary-long signed occurs 13483 times.
linkage section.
01 action-rd binary-long signed.
01 gate-count binary-long signed.
01 gate-table.
   02 gate-rd binary-long signed occurs 280 times.
01 requested-rank binary-long signed.
01 candidate-count binary-long signed.
01 candidate-table.
   02 candidate occurs 19600 times.
      03 opening-rd binary-long signed.
      03 closing-rd binary-long signed.
01 selected-open binary-long signed.
01 selected-close binary-long signed.
01 result-status binary-short unsigned.
procedure division using action-rd gate-count gate-table
    requested-rank candidate-count candidate-table
    selected-open selected-close result-status.
main.
    move 0 to candidate-count selected-open selected-close
    initialize candidate-table lookup-table
    move 22 to result-status
    if action-rd < -15075671 or action-rd > -15035671
       or gate-count < 2 or gate-count > 280
        goback
    end-if
    move gate-rd(1) to first-gate
    move gate-rd(gate-count) to last-gate
    if first-gate > action-rd - 5778
       or first-gate < action-rd - 6741
       or last-gate < action-rd + 5778
       or last-gate > action-rd + 6741
        goback
    end-if
    perform varying ix from 1 by 1 until ix > gate-count
        if ix > 1
            compute delta-days = gate-rd(ix) - gate-rd(ix - 1)
            if delta-days < 42 or delta-days > 963
                goback
            end-if
        end-if
        if gate-rd(ix) < first-gate or gate-rd(ix) > last-gate
            goback
        end-if
        compute slot-no = gate-rd(ix) - first-gate + 1
        move ix to gate-index(slot-no)
    end-perform
    *> Sort by construction: length first, then opening RD.
    perform varying span-days from 252 by 1 until span-days > 5778
        perform varying ix from 1 by 1 until ix > gate-count
            if gate-rd(ix) >= action-rd
                exit perform
            end-if
            if gate-rd(ix) + span-days >= action-rd
               and gate-rd(ix) + span-days <= last-gate
                compute slot-no = gate-rd(ix) + span-days
                    - first-gate + 1
                move gate-index(slot-no) to jx
                if jx >= ix + 6
                    add 1 to candidate-count
                    move gate-rd(ix) to opening-rd(candidate-count)
                    move gate-rd(jx) to closing-rd(candidate-count)
                end-if
            end-if
        end-perform
    end-perform
    move 0 to result-status
    if requested-rank = 0
        goback
    end-if
    if requested-rank < 1 or requested-rank > candidate-count
        move 23 to result-status
        goback
    end-if
    move opening-rd(requested-rank) to selected-open
    move closing-rd(requested-rank) to selected-close
    goback.
end program CALENDAR-YEAR-CANDIDATES.
