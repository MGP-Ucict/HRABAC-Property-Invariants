---------------- MODULE Invariant3_StateRecovery ----------------
EXTENDS Integers, Sequences

CONSTANTS PropertyHashes, Inspectors
VARIABLES 
    activeLedgerState,
    kafkaWAL,
    shadowNodeSynced

TypeOK ==
    /\ \forall p \in PropertyHashes : activeLedgerState[p] \in {TRUE, FALSE}
    /\ kafkaWAL \in Seq(PropertyHashes)
    /\ shadowNodeSynced \in {TRUE, FALSE}

Init ==
    /\ activeLedgerState = [p \in PropertyHashes |-> FALSE]
    /\ kafkaWAL = <<>>
    /\ shadowNodeSynced = TRUE

CommitAssetMutation(inspector, pHash) ==
    /\ activeLedgerState[pHash] = FALSE
    /\ activeLedgerState' = [activeLedgerState EXCEPT ![pHash] = TRUE]
    /\ kafkaWAL' = Append(kafkaWAL, pHash)
    /\ shadowNodeSynced' = TRUE

TriggerNetworkJitter ==
    /\ shadowNodeSynced' = FALSE
    /\ UNCHANGED <<activeLedgerState, kafkaWAL>>

RecoverShadowNode(pHash) ==
    /\ shadowNodeSynced = FALSE
    /\ activeLedgerState[pHash] = TRUE
    /\ \exists idx \in 1..Len(kafkaWAL) : kafkaWAL[idx] = pHash
    /\ shadowNodeSynced' = TRUE
    /\ UNCHANGED <<activeLedgerState, kafkaWAL>>

StateRecoveryInvariant ==
    \forall p \in PropertyHashes :
        (activeLedgerState[p] = TRUE \land shadowNodeSynced = TRUE) => (\exists idx \in 1..Len(kafkaWAL) : kafkaWAL[idx] = p)

Next == 
    \/ \exists i \in Inspectors, p \in PropertyHashes : CommitAssetMutation(i, p)
    \/ TriggerNetworkJitter
    \/ \exists p \in PropertyHashes : RecoverShadowNode(p)

Spec == Init /\ [][Next]_<<activeLedgerState, kafkaWAL, shadowNodeSynced>>
=============================================================================
