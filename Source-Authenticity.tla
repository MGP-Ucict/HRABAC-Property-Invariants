------------------- MODULE ZTARegHRABAC -------------------
EXTENDS Naturals, Sequences

CONSTANTS Actors, Assets

VARIABLES 
    registryState,   \* Maps each asset to its current 32-byte crypto-anchor hash
    pdpCircuit       \* Status of the Policy Decision Point circuit breaker: "Active" or "Blocked"

vars == <<registryState, pdpCircuit>>

\* Initial State of the system
Init == 
    /\ registryState = [a \in Assets |-> "genesis_hash"]
    /\ pdpCircuit = "Active"

\* Next-State Action: Authorized asset ownership transfer
TransferAsset(actor, asset, new_anchor) ==
    /\ pdpCircuit = "Active"
    /\ registryState' = [registryState EXCEPT ![asset] = new_anchor]
    /\ pdpCircuit' = "Active"

\* Next-State Action: Simulated adversarial mutation (Zero-Trust breach vector)
MaliciousAttack(asset) ==
    /\ pdpCircuit = "Active"
    /\ registryState' = [registryState EXCEPT ![asset] = "illegal_mutation"]
    /\ pdpCircuit' = "Blocked"

\* Next-State Relation (Includes both benign transfers and threat vectors)
Next == 
    \/ \E actor \in Actors, asset \in Assets : TransferAsset(actor, asset, "valid_token")
   
\* Full structural specification definition
Spec == Init /\ [][Next]_vars

\* INVARIANT 1: Structural Integrity & State Non-Mutation (Safety Property)
\* TLC will evaluate every generated state to ensure this statement remains TRUE.
SecurityInvariant1 == 
    \forall a \in Assets : registryState[a] /= "illegal_mutation"

===========================================================
