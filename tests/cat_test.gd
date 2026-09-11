extends SceneTree
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		push_error(message)
		failures += 1

func _initialize() -> void:
	var trail := Battle.new(18)
	trail.weapons.assign([1, 1, 0])
	trail._weapons(0.1)
	check(trail.fur_patches.is_empty(), "Stationary cat must not generate a movement trail")
	trail.moving = true
	trail._weapons(0.5)
	check(trail.fur_patches.size() == 1, "Moving cat must leave fur behind")
	trail.moving = false
	trail._weapons(0.5)
	check(trail.fur_patches.size() == 1, "Stopping must stop new fur patches")
	var bounce := Battle.new(8)
	bounce.weapons.assign([1, 0, 1])
	bounce.cap_clock = 0
	bounce.paw_clock = 100
	for x in [120, 155, 185]:
		bounce.spawn_enemy(0, bounce.player + Vector2(x, 0))
	bounce._rebuild_grid()
	bounce._weapons(0.01)
	for frame in 150:
		bounce._projectiles(0.02)
	check(bounce.kills == 3, "A cap must bounce through three distinct spirits")
	check(bounce.damage_dealt[2] == 48, "Cap damage must count once for each of three targets")
	var bones := Battle.new(5)
	for x in [100, 140, 190]:
		bones.spawn_enemy(0, bones.player + Vector2(x, 0))
	bones._rebuild_grid()
	bones._weapons(0.01)
	for frame in 60:
		bones._projectiles(0.02)
	check(bones.kills == 2 and bones.damage_dealt[0] == 32, "A base fishbone must pierce exactly two targets in a straight line")
	var shelter := Battle.new(12)
	shelter.player = shelter.landmarks[0].at
	shelter._city_objects(0.1)
	check(shelter.hidden, "Standing inside a box must hide the cat")
	shelter.hurt_player(20)
	check(shelter.hp == 100, "Box cover must absorb incoming damage briefly")
	for frame in 240:
		shelter._city_objects(1.0 / 60)
	check(not shelter.hidden and shelter.hide_charge == 0, "Box must expire without recharging while camping")
	shelter.hurt_player(20)
	check(shelter.hp == 80, "Expired box cannot grant permanent invulnerability")
	var food := Battle.new(2)
	food.hp = 40
	food.pickups.spawn(food.player, 2, 12, Vector2.ZERO, 22)
	food._collect(0.01)
	check(food.hp == 52 and food.food_boost == 4, "Churu must heal and grant its movement bonus")
	food.pickups.spawn(food.player, 3, 8, Vector2.ZERO, 22)
	food._collect(0.01)
	check(food.hp == 60 and food.food_regen == 6, "Fish must grant ongoing recovery")
	var restored := Battle.new(3)
	check(restored.restore(food.snapshot()), "Cat run save must restore")
	check(restored.food_boost == 4 and restored.food_regen == 6, "Save must retain food effects")
	for i in 100:
		food.food_clock = 0
		food._city_objects(0.01)
	for i in food.pickups.capacity:
		if food.pickups.alive[i]:
			check(not food._building_at(food.pickups.position[i]), "Food must not spawn inside a building")
	var overtime := Battle.new(7)
	overtime.elapsed = 905
	overtime.god_mode = true
	var boss := overtime.spawn_enemy(7, overtime.player + Vector2(100, 0))
	overtime.fired_events[840] = true
	overtime.step(0.1, Vector2.ZERO)
	check(not overtime.finished, "Passing fifteen minutes must not bypass the boss")
	var continued := Battle.new(3)
	check(continued.restore(overtime.snapshot()), "Overtime boss fight must remain resumable")
	overtime._hurt_enemy(boss, 100000, 0)
	check(overtime.finished and overtime.victory and overtime.fired_events.has("boss_defeated"), "Defeating the stage boss must clear the stage")
	var walls := Battle.new(7)
	walls.player = Vector2(315, 30)
	walls.god_mode = true
	walls.step(0.1, Vector2.RIGHT)
	check(walls.player.x == 315, "Building facade must block walking through it")
	print("CAT_TEST_OK" if failures == 0 else "CAT_TEST_FAILED")
	quit(1 if failures else 0)
