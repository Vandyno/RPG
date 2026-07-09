extends GutTest

const ActorState = preload("res://scripts/core/actor_state.gd")


func test_actor_state_constants_keep_shared_state_contract() -> void:
	assert_eq(ActorState.ALIVE, "alive")
	assert_eq(ActorState.UNCONSCIOUS, "unconscious")
	assert_eq(ActorState.DEAD, "dead")
	assert_eq(ActorState.DEAD_BODY, "dead_body")
	assert_eq(ActorState.DESPAWNED, "despawned")
	assert_eq(ActorState.DEFAULT, ActorState.ALIVE)
	assert_eq(
		ActorState.VALID_STATES,
		[ActorState.ALIVE, ActorState.UNCONSCIOUS, ActorState.DEAD_BODY, ActorState.DESPAWNED]
	)
	assert_eq(
		ActorState.DEAD_STATES,
		[ActorState.DEAD, ActorState.DEAD_BODY, ActorState.DESPAWNED]
	)
