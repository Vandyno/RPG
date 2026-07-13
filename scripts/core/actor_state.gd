class_name ActorState
extends RefCounted

const ALIVE := "alive"
const UNCONSCIOUS := "unconscious"
const DEAD := "dead"
const DEAD_BODY := "dead_body"
const DESPAWNED := "despawned"
const VALID_STATES := [ALIVE, UNCONSCIOUS, DEAD, DEAD_BODY, DESPAWNED]
const DEAD_STATES := [DEAD, DEAD_BODY, DESPAWNED]
const DEFAULT := ALIVE
