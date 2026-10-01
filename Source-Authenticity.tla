---------------- MODULE Invariant1_SourceAuthenticity ----------------
EXTENDS Integers, Sequences

CONSTANTS PropertyHashes, EpochRoots, Inspectors
VARIABLES 
    properties,
    validatedEpochs

TypeOK ==
    /\ \forall p \in PropertyHashes : 
        /\ properties[p].epochRoot \in (EpochRoots \cup {0})
        /\ properties[p].isDeactivated \in {TRUE, FALSE}
    /\ \forall e \in EpochRoots : 
        validatedEpochs[e] \in {TRUE, FALSE}

Init ==
    /\ properties = [p \in PropertyHashes |-> [epochRoot |-> 0, isDeactivated |-> FALSE]]
    /\ validatedEpochs = [e \in EpochRoots |-> FALSE]

EmitEpochState(inspector, epochRoot, pHash) ==
    /\ epochRoot /= 0
    /\ validatedEpochs[epochRoot] = FALSE
    /\ properties[pHash].epochRoot = 0
    /\ properties' = [properties EXCEPT ![pHash] = [epochRoot |-> epochRoot, isDeactivated |-> FALSE]]
    /\ validatedEpochs' = [validatedEpochs EXCEPT ![epochRoot] = TRUE]

SourceAuthenticityInvariant ==
    \forall p \in PropertyHashes :
        (properties[p].epochRoot /= 0) => (validatedEpochs[properties[p].epochRoot] = TRUE)

Next == 
    \exists i \in Inspectors, e \in EpochRoots, p \in PropertyHashes : 
        EmitEpochState(i, e, p)

Spec == Init /\ [][Next]_<<properties, validatedEpochs>>
=============================================================================
