# CICATRIX MEMORIAE HTTP — Patch 38 sepulcrum grande non persistit in binary
# deploymentis humili memoria.  Fons historicus src/monster.cpp non mutatur.
# Duo tantum ostia vault clauduntur: resurrectio et burial skeletonis legalis.

BEGIN {
    resurrection = 0
    burial = 0
}

{
    line = $0

    if (line ~ /^[[:space:]]*if \(accelerationsOn\(\) && !fullHistoricalValidationOn\(\)\) \{[[:space:]]*$/) {
        if ((getline nextline) <= 0) {
            print "cicatrix memoriae: EOF post condicionem resurrectionis" > "/dev/stderr"
            exit 41
        }
        if (nextline ~ /legalWeavingSkeletonVaultMutex/) {
            sub(/if \(accelerationsOn\(\) && !fullHistoricalValidationOn\(\)\) \{/, \
                "if (false and accelerationsOn() and !fullHistoricalValidationOn()) {", line)
            resurrection++
        }
        print line
        print nextline
        next
    }

    if (line ~ /^[[:space:]]*if \(accelerationsOn\(\)\) \{[[:space:]]*$/) {
        if ((getline nextline) <= 0) {
            print "cicatrix memoriae: EOF post condicionem burial" > "/dev/stderr"
            exit 42
        }
        if (nextline ~ /LegalWeavingSkeletonBones born[[:space:]]*\{/) {
            sub(/if \(accelerationsOn\(\)\) \{/, \
                "if (false and accelerationsOn()) {", line)
            burial++
        }
        print line
        print nextline
        next
    }

    print line
}

END {
    if (resurrection != 1 || burial != 1) {
        print "cicatrix memoriae: Patch38 forma mutata est; resurrection=" resurrection \
              " burial=" burial > "/dev/stderr"
        exit 43
    }
}
