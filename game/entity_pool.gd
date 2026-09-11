class_name EntityPool
extends RefCounted

var capacity: int
var alive := PackedByteArray()
var position := PackedVector2Array()
var velocity := PackedVector2Array()
var health := PackedFloat32Array()
var kind := PackedInt32Array()
var timer := PackedFloat32Array()
var aux := PackedFloat32Array()
var burn := PackedFloat32Array()
var generation := PackedInt32Array()
var free: Array[int] = []
var count := 0

func _init(size: int = 500) -> void:
	capacity = size
	for buffer in [alive, position, velocity, health, kind, timer, aux, burn, generation]:
		buffer.resize(size)
	# Packed arrays use copy-on-write; explicitly size member buffers.
	alive.resize(size)
	position.resize(size)
	velocity.resize(size)
	health.resize(size)
	kind.resize(size)
	timer.resize(size)
	aux.resize(size)
	burn.resize(size)
	generation.resize(size)
	for i in range(size - 1, -1, -1):
		free.append(i)

func spawn(at: Vector2, type: int, hp: float, motion := Vector2.ZERO, life := 0.0) -> int:
	if free.is_empty():
		return -1
	var id: int = free.pop_back()
	alive[id] = 1
	position[id] = at
	velocity[id] = motion
	health[id] = hp
	kind[id] = type
	timer[id] = life
	aux[id] = 0.0
	burn[id] = 0.0
	generation[id] += 1
	count += 1
	return id

func release(id: int) -> void:
	if id < 0 or id >= capacity or alive[id] == 0:
		return
	alive[id] = 0
	free.append(id)
	count -= 1

func snapshot() -> Dictionary:
	return {"alive": alive, "position": position, "velocity": velocity,
		"health": health, "kind": kind, "timer": timer, "aux": aux,
		"burn": burn, "generation": generation, "free": free, "count": count}

func restore(data: Dictionary) -> void:
	alive = data.alive
	position = data.position
	velocity = data.velocity
	health = data.health
	kind = data.kind
	timer = data.timer
	aux = data.aux
	burn = data.burn
	generation = data.generation
	free.assign(data.free)
	count = data.count
