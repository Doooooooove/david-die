extends SceneTree

var game: Node
var failed = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: " + description)

func finish_dialogue() -> void:
	while game.state == "dialogue":
		game.advance_dialogue()

func run() -> void:
	game = load("res://main.tscn").instantiate()
	game.saving_enabled = false
	game.muted = true
	root.add_child(game)
	game.set_process(false)
	await process_frame
	await process_frame
	game.start_boss(0)
	check(game.state == "dialogue", "Opening boss has an introduction")
	finish_dialogue()
	game.player = game.boss + Vector2(-24, 0)
	game.boss_phase = "recover"
	var before: float = game.boss_hp
	game.try_attack()
	check(game.boss_hp < before, "A close-range attack damages the boss")
	game.try_attack()
	check(game.boss_hp == before - 18, "Attack cooldown prevents frame-rate damage")
	game.try_dash()
	check(not game.hurt_player(25) and game.player_hp == 100, "Dash invulnerability prevents damage")
	game.invulnerable = 0
	game.hurt_player(25)
	check(game.player_hp == 75 and not game.hurt_player(25), "Damage grants a short invulnerability window")
	game.hit_boss(10000)
	finish_dialogue()
	check(game.state == "street", "First victory leads to the hospital journey")
	game.player = Vector2(424, 114)
	game.interact()
	check(game.state == "street", "The hospital cannot be entered before glasses are repaired")
	game.player = Vector2(177, 166)
	game.drop_pad()
	game.refresh()
	check(game.blur.visible, "Dropping the nose pad blurs the world")
	game.player = game.pad_pos
	game.interact()
	check(game.state == "glasses", "The dropped pad can be picked up")
	check(not game.fit_pad(Vector2(100, 100)) and not game.pad_fixed, "Dropping the pad outside its socket does not install it")
	# Send real mouse events through the drag interaction.
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = game.glass_pad
	game._input(press)
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(491, 278)
	game._input(motion)
	press.pressed = false
	press.position = motion.position
	game._input(press)
	game.refresh()
	check(game.pad_fixed and game.state == "street" and not game.blur.visible, "Dragging the nose pad into its socket restores clear vision")
	game.player = Vector2(424, 114)
	game.interact()
	check(game.state == "hospital", "Repaired glasses allow hospital entry")
	game.player = Vector2(433, 198)
	game.interact()
	check(game.state == "hospital", "Hospital exit is gated on the CT examination")
	game.player = Vector2(325, 143)
	game.interact()
	check(game.state == "hospital", "Doctor consultation precedes the CT")
	game.player = Vector2(139, 131)
	game.interact()
	finish_dialogue()
	game.player = Vector2(325, 143)
	game.interact()
	check(game.state == "ct", "Consulting the doctor unlocks CT scanning")
	game._process(6.01)
	finish_dialogue()
	check(game.scanned and game.state == "hospital", "CT completes and returns the player to the hospital")
	game.player = Vector2(433, 198)
	game.interact()
	finish_dialogue()
	check(game.boss_index == 1 and game.state == "fight", "Hospital exit progresses to the second boss")
	for index in [1, 2, 3]:
		check(game.boss_index == index, "Boss order %d is preserved" % (index + 1))
		game.hit_boss(10000)
		check(game.state == "dialogue" and game.letter_pos == Vector2.ZERO, "Boss %d speaks without dropping the final letter" % (index + 1))
		if index == 3:
			check(game.speaker == "1006" and "David" in game.dialogue[0], "Cow 1006 gives a spoken clue about David")
		finish_dialogue()
	check(game.boss_index == 4 and game.state == "fight", "David is the fifth and final boss")
	game.hit_boss(10000)
	check(game.state == "letter_pickup" and game.letter_pos != Vector2.ZERO, "Only David drops the letter")
	game.player = game.letter_pos
	game.interact()
	check(game.state == "letter", "The final letter can be picked up and read")
	game.start_boss(4, false)
	game.hurt_player(100)
	check(game.state == "dead", "Player death enters the retry screen")
	game.start_boss(4, false)
	check(game.player_hp == 100 and game.boss_hp == game.boss_max_hp and game.projectiles.is_empty(), "Retry resets health and hazards")
	# Exercise full combat loops at 60 Hz using ordinary attack and dash actions.
	for index in range(5):
		game.start_boss(index, false)
		var elapsed = 0.0
		while game.state == "fight" and elapsed < 65:
			var direction: Vector2 = (game.boss - game.player).normalized()
			for action in ["left", "right", "up", "down"]:
				Input.action_release(action)
			if direction.x > 0.15: Input.action_press("right")
			if direction.x < -0.15: Input.action_press("left")
			if direction.y > 0.15: Input.action_press("down")
			if direction.y < -0.15: Input.action_press("up")
			Input.action_press("attack")
			if game.boss_phase == "windup" and game.boss_timer < 0.18:
				game.try_dash()
			game.update_player(1.0 / 60)
			if game.state == "fight":
				game.update_boss(1.0 / 60)
				game.update_attacks(1.0 / 60)
			game.update_effects(1.0 / 60)
			elapsed += 1.0 / 60
		check(game.boss_hp == 0 and game.player_hp > 0, "Boss %d can be defeated with normal movement, attack and dash (%.1fs, HP %.0f)" % [index + 1, elapsed, game.player_hp])
	for action in ["left", "right", "up", "down", "attack"]: Input.action_release(action)
	print("RESULT: %d / %d checks passed" % [checks - failed, checks])
	game.free()
	game = null
	call_deferred("quit", 1 if failed else 0)
