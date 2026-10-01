---------------- MODULE Invariant4_GDPRAndAICutoff ----------------
EXTENDS Integers

CONSTANTS PropertyHashes, CitizenHashes, Inspectors
VARIABLES 
    ownershipRegistry,
    ownershipShares,
    tCurrent,
    isActiveSession

T_INIT == 100
T_TOLERANCE == 20
T_SECURE == 70

TypeOK ==
    /\ \forall p \in PropertyHashes : \forall c \in CitizenHashes : ownershipRegistry[p][c] \in {TRUE, FALSE}
    /\ \forall p \in PropertyHashes : \forall c \in CitizenHashes : ownershipShares[p][c] \in Int
    /\ \forall i \in Inspectors : tCurrent[i] \in 0..100
    /\ \forall i \in Inspectors : isActiveSession[i] \in {TRUE, FALSE}

Init ==
    /\ ownershipRegistry = [p \in PropertyHashes |-> [c \in CitizenHashes |-> FALSE]]
    /\ ownershipShares = [p \in PropertyHashes |-> [c \in CitizenHashes |-> 0]]
    /\ tCurrent = [i \in Inspectors |-> T_INIT]
    /\ isActiveSession = [i \in Inspectors |-> TRUE]

ProcessAIAnomalyPenalty(inspector, penaltyScore) ==
    LET evaluationScore == tCurrent[inspector] - penaltyScore
    LET currentTrust == IF evaluationScore < 0 THEN 0 ELSE evaluationScore
    IN  /\ tCurrent' = [tCurrent EXCEPT ![inspector] = currentTrust]
        /\ isActiveSession' = [isActiveSession EXCEPT ![inspector] = (currentTrust > T_TOLERANCE)]
        /\ UNCHANGED <<ownershipRegistry, ownershipShares>>

RevokeSingleOwnerAnchor(inspector, pHash, cHash) ==
    /\ isActiveSession[inspector] = TRUE
    /\ tCurrent[inspector] >= T_SECURE
    /\ ownershipRegistry[pHash][cHash] = TRUE
    /\ ownershipRegistry' = [ownershipRegistry EXCEPT ![pHash][cHash] = FALSE]
    /\ ownershipShares' = [ownershipShares EXCEPT ![pHash][cHash] = 0]
    /\ UNCHANGED <<tCurrent, isActiveSession>>

GDPRAndAICutoffInvariant ==
    /\ \forall p \in PropertyHashes, c \in CitizenHashes : (ownershipRegistry[p][c] = FALSE) => (ownershipShares[p][c] = 0)
    /\ \forall i \in Inspectors : (tCurrent[i] <= T_TOLERANCE) => (isActiveSession[i] = FALSE)

Next == 
    \exists i \in Inspectors, p \in PropertyHashes, c \in CitizenHashes :
        \/ ProcessAIAnomalyPenalty(i, 45)
        \/ RevokeSingleOwnerAnchor(i, p, c)

Spec == Init /\ [][Next]_<<ownershipRegistry, ownershipShares, tCurrent, isActiveSession>>
=============================================================================
