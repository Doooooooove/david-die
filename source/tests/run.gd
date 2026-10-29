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
	check(game.state == "dialogue" and "高申" in game.dialogue[0] and "偷走" in game.dialogue[0], "The opening explains that David stole Gaoshen's parcel")
	check(game.Story.BOSSES.size() == 4 and game.Story.BOSSES[2].name == "1006", "Removing the placeholder leaves four bosses in the correct order")
	finish_dialogue()
	game.player = game.boss + Vector2(-24, 0)
	game.boss_phase = "recover"
	var before: float = game.boss_hp
	game.try_attack()
	check(game.boss_hp < before, "A close-range attack damages the boss")
	game.try_attack()
	check(game.boss_hp == before - 10, "Attack cooldown prevents frame-rate damage")
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
	check(game.boss_index == 1 and game.state == "beach", "Hospital exit leads to the beach before the hidden second boss")
	game.hit_boss(10000)
	check(game.boss_hp == game.boss_max_hp and game.state == "beach", "The hidden whale cannot be attacked before it is fished out")
	game.player = game.FISHING_SPOT
	game.interact()
	check(game.state == "beach", "Fishing requires picking up the rod first")
	game.player = Vector2(430, 210)
	game.interact()
	check(not game.has_fishing_rod, "The fishing rod cannot be picked up from across the beach")
	game.player = game.FISHING_ROD
	game.interact()
	check(game.has_fishing_rod and game.state == "beach", "Lingzhi can pick up the fishing rod on the sand")
	game.player = game.FISHING_SPOT
	game.interact()
	check(game.state == "fishing", "Casting from the shore starts fishing instead of combat")
	game.interact()
	check(game.state == "fishing", "Reeling in too early does not reveal the hidden boss")
	game._process(1.81)
	game.interact()
	check(game.state == "reeling", "A bite begins the interactive reeling challenge")
	game.reel_time = PI / 5.0
	game.attempt_reel()
	game._process(TAU / 5.0)
	game.attempt_reel()
	check(game.state == "fished", "Reeling in after a bite lifts the small whale out of the sea")
	game._process(1.21)
	check(game.state == "dialogue" and "DeepSeek" in game.dialogue[0], "The catch is introduced as the DeepSeek whale")
	finish_dialogue()
	check(game.state == "fight" and game.boss_hp == 190 and game.player_hp == 100, "The whale's boss fight starts with full health after the reveal")
	game.boss_pattern = 1
	game.boss_target = game.player
	game.perform_boss_attack()
	check(game.boss_phase == "airborne" and game.projectiles.is_empty(), "The small whale flies up for a slam instead of shooting bubbles")
	var whale_health: float = game.boss_hp
	game.hit_boss(18)
	check(game.boss_hp == whale_health, "An airborne whale cannot be hit by a ground attack")
	game.update_boss(0.5)
	check(game.player_hp == 100, "The whale does not deal damage before landing")
	var landing: Vector2 = game.boss_target
	game.player = landing + Vector2(55, 0)
	game.update_boss(0.51)
	check(game.player_hp == 100 and game.boss == landing and game.boss_phase == "recover", "Moving away from the locked landing point avoids the slam and leaves a recovery opening")
	game.boss_target = game.player
	game.perform_boss_attack()
	game.update_boss(1.01)
	check(game.player_hp == 76, "Standing in the landing circle takes exactly one slam hit")
	game.player_hp = 100
	for index in [1, 2]:
		check(game.boss_index == index, "Boss order %d is preserved" % (index + 1))
		game.hit_boss(10000)
		check(game.state == "dialogue" and game.letter_pos == Vector2.ZERO, "Boss %d speaks without dropping the final letter" % (index + 1))
		if index == game.COW_BOSS:
			check(game.speaker == "1006" and "David" in game.dialogue[0], "Cow 1006 gives a spoken clue about David")
		finish_dialogue()
		check(game.state == "route" and game.boss_index == index, "Victory %d leads to a walkable connecting scene" % (index + 1))
		game.interact()
		check(game.state == "route", "The next encounter requires walking to its entrance")
		game.player = game.ROUTE_EXIT
		game.interact()
		finish_dialogue()
	check(game.boss_index == game.FINAL_BOSS and game.state == "fight", "David is the fourth and final boss after following 1006's warehouse clue")
	game.hit_boss(10000)
	check(game.state == "dialogue" and game.dialogue_next == "letter_pickup", "David explains the blank letter before the player collects it")
	finish_dialogue()
	check(game.state == "letter_pickup" and game.letter_pos != Vector2.ZERO, "Only David drops the letter")
	game.player = game.letter_pos
	game.interact()
	check(game.state == "letter" and game.has_letter and game.has_parcel, "David's letter and the stolen parcel are recovered together; the letter is blank in ordinary light")
	game._process(0)
	game.state = "aftermath"
	game.update_special_light(5, true, Vector2(200, 200))
	check(not game.birthday_revealed and game.illumination == 0, "The letter cannot be decoded in the lit boss room")
	game.player = game.DARK_DOOR
	game.interact()
	check(game.state == "darkroom", "The final door leads to a dark room after collecting the letter")
	game.player = game.LETTER_TABLE
	game.interact()
	check(game.state == "darkroom", "The dark room requires picking up the special light first")
	game.player = game.LIGHT_STAND
	game.interact()
	check(game.has_special_light, "The special light can be picked up inside the dark room")
	game.player = game.LETTER_TABLE
	game.interact()
	check(game.state == "illuminate", "The letter can be placed under the special light at the table")
	Input.action_press("special_light")
	game._process(0)
	Input.action_release("special_light")
	check(game.special_light_on, "F switches the special light on without requiring a held key")
	game.update_special_light(5, false, Vector2(200, 200))
	check(game.illumination == 0 and not game.birthday_revealed, "An unlit lamp does not reveal the birthday")
	game.update_special_light(5, true, Vector2(800, 200))
	check(game.illumination == 0 and not game.birthday_revealed, "Pointing the light away from the letter does not reveal it")
	game.update_special_light(1.0, true, Vector2(200, 200))
	check(game.state == "illuminate" and not game.birthday_revealed, "Brief illumination does not prematurely reveal the room")
	game.update_special_light(1.3, true, Vector2(200, 200))
	check(game.state == "birthday_reveal" and not game.birthday_revealed, "Full illumination reveals the text before the birthday lights turn on")
	game.update_birthday(1.01)
	check(game.birthday_revealed and "20" in game.Story.LETTER, "The neighboring room lights up for Lingzhi's twentieth birthday")
	game.state = "birthday"
	game.player = Vector2(60, 190)
	game.interact()
	check(game.state == "birthday" and not game.parcel_opened, "The final parcel must be approached before opening it")
	game.player = game.BIRTHDAY_PARCEL
	game.interact()
	check(game.state == "parcel_opening" and not game.parcel_opened, "The player can open the recovered parcel after the birthday reveal")
	game._process(1.0)
	check(game.state == "parcel_opening" and not game.parcel_opened, "Opening the parcel plays an animation before signing for it")
	game._process(1.5)
	check(game.state == "ending" and game.parcel_opened, "The parcel opening completes the birthday ending")
	game.start_boss(game.COW_BOSS, false)
	game.boss_phase = "approach"
	game.boss_timer = 0
	game.update_boss(0.01)
	check(game.boss_pattern == 4, "Cow 1006 opens with the red-envelope rain pattern")
	game.perform_boss_attack()
	check(game.red_packets.size() == 7, "Cow 1006 creates a shower of seven red envelopes")
	var packet = game.red_packets[0]
	game.player = packet.p
	game.update_attacks(0.5)
	check(game.player_hp == 100, "Red envelopes warn before impact instead of causing immediate damage")
	game.update_attacks(0.41)
	check(game.player_hp == 84, "A red envelope damages the player when it hits its warned landing point")
	game.red_packets.clear()
	game.boss_phase = "approach"
	game.boss_timer = 0
	game.update_boss(0.01)
	check(game.boss_pattern == 3, "Cow 1006 alternates rain with the red charge")
	game.hit_boss(10000)
	check(game.red_packets.is_empty(), "Defeating 1006 clears remaining envelope hazards")
	game.start_boss(game.FINAL_BOSS, false)
	game.hurt_player(100)
	check(game.state == "dead", "Player death enters the retry screen")
	game.start_boss(game.FINAL_BOSS, false)
	check(game.player_hp == 100 and game.boss_hp == game.boss_max_hp and game.projectiles.is_empty() and not game.birthday_revealed and not game.has_parcel and not game.parcel_opened, "Retry resets health, hazards and birthday parcel progress")
	game.start_boss(1, false)
	check(game.state == "fight", "Retrying the whale fight does not repeat fishing")
	game.start_boss(1)
	check(game.state == "beach" and not game.has_fishing_rod and game.fishing_time == 0, "Continuing chapter two restores the beach discovery sequence")
	test_playability()
	test_death_choices()
	await process_frame
	test_radio_bridge()
	await process_frame
	test_story_polish()
	await process_frame
	test_expansion()
	await process_frame
	test_practice_and_save()
	await process_frame
	# Exercise full combat loops at 60 Hz using ordinary attack and dash actions.
	for index in range(game.Story.BOSSES.size()):
		game.start_boss(index, false)
		var elapsed = 0.0
		while game.state == "fight" and elapsed < 65:
			var destination: Vector2 = game.boss
			if index == 1 and ((game.player.x < 192 and game.boss.x >= 192) or (game.player.x >= 288 and game.boss.x < 288) or game.WHALE_LAVA.has_point(game.player)):
				# Cross on the radio bridge before pursuing a whale on the other bank.
				destination = Vector2(game.player.x, 190) if absf(game.player.y - 190) > 3 else Vector2(clampf(game.boss.x, 175, 305), 190)
			var direction: Vector2 = (destination - game.player).normalized()
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

func test_playability() -> void:
	game.start_boss(0, false)
	game.player = game.boss - Vector2(25, 0)
	game.boss_phase = "recover"
	var hp: float = game.boss_hp
	game.try_attack()
	game.update_player(0.24)
	game.try_attack()
	game.update_player(0.24)
	game.try_attack()
	check(game.combo_step == 3 and game.boss_hp == hp - 38, "Three consecutive attacks finish with a stronger third strike")
	game.update_player(0.9)
	game.try_attack()
	check(game.combo_step == 1, "Pausing attacks resets the combo instead of banking a permanent heavy strike")
	game.start_boss(0, false)
	game.try_dash()
	game.hurt_player(20)
	var cooldown: float = game.dash_cd
	check(game.player_hp == 100 and game.counter_time > 0 and cooldown < 0.72, "Dodging through an actual hit grants a counter and shortens the next dash cooldown")
	game.hurt_player(20)
	check(game.dash_cd == cooldown, "Multiple overlapping hazards reward one dash only once")
	game.dash_time = 0
	game.player = Vector2(40, 120)
	game.try_attack()
	check(game.counter_time > 0, "A missed counterattack does not consume the reward")
	game.player = game.boss - Vector2(25, 0)
	game.attack_cd = 0
	game.combo_time = 0
	game.boss_phase = "recover"
	hp = game.boss_hp
	game.try_attack()
	check(game.boss_hp == hp - 22 and game.counter_time == 0, "The next successful counterattack deals its bonus exactly once")
	game.counter_time = 0
	game.dash_rewarded = false
	game.invulnerable = 0.5
	game.hurt_player(20)
	check(game.counter_time == 0, "Ordinary damage immunity cannot farm dodge rewards")
	game.start_boss(0, false)
	game.dash_cd = 0.08
	game.hitstop = 0.05
	var dash = InputEventKey.new()
	dash.physical_keycode = KEY_SPACE
	dash.pressed = true
	game._input(dash)
	game.update_player(0.09)
	check(game.dash_time > 0 and game.invulnerable > 0, "A dash pressed just before cooldown ends is buffered instead of lost")
	game.start_boss(0, false)
	check(not game.try_heal() and game.heal_charges == 1, "Full health does not waste the one-use supply")
	game.hurt_player(40)
	check(game.try_heal() and game.player_hp == 95 and game.heal_charges == 0, "Emergency supplies restore 35 health once per fight")
	check(not game.try_heal(), "Supplies cannot be used twice in one fight")
	game.start_boss(1, false)
	game.player_hp = 90
	game.try_heal()
	check(game.player_hp == 100, "Healing is capped at full health")
	game.start_boss(0, false)
	game.hit_boss(game.boss_max_hp * 0.51)
	game.attack_count = 1
	game.boss_phase = "approach"
	game.boss_timer = 0
	game.update_boss(0.01)
	check(game.boss_enraged and game.boss_pattern == 3, "The screening boss introduces a charge in its second phase")
	game.start_boss(1, false)
	game.hit_boss(game.boss_max_hp * 0.51)
	game.boss_target = Vector2(200, 180)
	game.player = Vector2(270, 180)
	game.perform_boss_attack()
	game.update_boss(1.01)
	check(game.boss_phase == "windup" and game.slam_chain == 1 and game.boss_target == game.player, "The enraged whale warns again and locks a new target before its second slam")
	game.player = Vector2(200, 180)
	game.perform_boss_attack()
	game.update_boss(1.01)
	check(game.boss_phase == "recover" and game.boss_timer >= 1.5 and game.player_hp == 100, "Avoiding both whale slams grants a longer recovery opening")
	game.start_boss(game.COW_BOSS, false)
	game.hit_boss(game.boss_max_hp * 0.51)
	game.boss_pattern = 4
	game.perform_boss_attack()
	check(game.red_packets.size() == 9 and game.red_packets[0].remaining >= 0.9, "The second-phase envelope rain grows denser while preserving landing warnings")
	game.start_boss(game.FINAL_BOSS, false)
	game.hit_boss(game.boss_max_hp * 0.51)
	game.attack_count = 1
	game.boss_phase = "approach"
	game.boss_timer = 0
	game.update_boss(0.01)
	check(game.boss_pattern == 3, "David adds more charges to the second-phase attack sequence")
	game.start_boss(1, false)
	check(not game.boss_enraged and game.slam_chain == 0 and game.combo_step == 0 and game.counter_time == 0 and game.heal_charges == 1, "Retry clears combat rewards and second-phase state and restores supplies")
	game.state = "route"
	game.player = Vector2(60, 181)
	Input.action_press("right")
	game.update_player(0.5)
	var walked: float = game.player.x - 60
	game.player = Vector2(60, 181)
	Input.action_press("dash")
	game.update_player(0.5)
	check(game.player.x - 60 > walked * 1.4 and game.dash_time == 0, "Holding dash outside combat speeds up exploration without a combat roll")
	Input.action_release("right")
	Input.action_release("dash")
	game.state = "illuminate"
	game.has_letter = true
	game.has_special_light = true
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(200, 200)
	game._input(click)
	check(game.special_light_on, "Clicking the letter provides a mouse alternative to the special-light key")
	game.update_special_light(2.3, game.special_light_on, click.position)
	check(game.state == "birthday_reveal", "The mouse-operated light can finish the birthday puzzle")

func test_story_polish() -> void:
	game.start_boss(0)
	check(game.dialogue_visible == 0 and game.journal_stage() == 0, "A new conversation starts unrevealed with the current investigation task")
	game._process(0.1)
	check(game.dialogue_visible > 0 and game.dialogue_visible < game.dialogue[0].length(), "Dialogue reveals progressively without advancing by itself")
	game.advance_dialogue()
	check(game.dialogue_index == 0 and game.dialogue_visible == game.dialogue[0].length(), "The first confirm reveals the full line instead of skipping it")
	game.advance_dialogue()
	check(game.dialogue_index == 1 and game.dialogue_visible == 0, "A second confirm advances to the next speaker")
	finish_dialogue()
	var key = InputEventKey.new()
	key.physical_keycode = KEY_TAB
	key.pressed = true
	game._input(key)
	var timer: float = game.boss_timer
	var position: Vector2 = game.player
	Input.action_press("right")
	game._process(1.0)
	Input.action_release("right")
	check(game.journal_open and game.boss_timer == timer and game.player == position, "The task journal pauses both combat and movement")
	key.physical_keycode = KEY_ESCAPE
	game._input(key)
	game._process(0.1)
	check(not game.journal_open and game.state == "fight" and game.boss_timer == timer, "Escape closes the journal without opening another pause menu")
	game.begin_dialogue(["灵芝：先去医院。"], "street")
	check(game.journal_stage() == 1, "The journal follows the hospital lead during the transition dialogue")
	game.start_boss(1, false)
	game.begin_dialogue(["高申：沿栈道去档案室。"], "route")
	check(game.journal_stage() == 3, "The recovered pass advances the journal to the archive task")
	game.start_boss(0, false)
	game.player = game.boss - Vector2(25, 0)
	game.boss_phase = "recover"
	game.boss_timer = 0.3
	game.combo_step = 2
	game.combo_time = 0.7
	game.try_attack()
	check(game.recovery_staggered and is_equal_approx(game.boss_timer, 0.75), "A heavy third hit extends a recovery opening")
	game.attack_cd = 0
	game.combo_step = 2
	game.try_attack()
	check(is_equal_approx(game.boss_timer, 0.75), "Repeated heavy hits cannot hold a boss in recovery forever")
	game.boss_pattern = 0
	game.perform_boss_attack()
	check(not game.recovery_staggered, "A new boss attack resets its single stagger opportunity")
	game.start_boss(game.COW_BOSS, false)
	game.boss = Vector2(425, 160)
	game.boss_dir = Vector2.RIGHT
	game.boss_pattern = 3
	game.perform_boss_attack()
	game.update_boss(0.05)
	check(game.boss.x == 431 and game.boss_phase == "recover" and game.boss_timer == 1.8, "A charge into the wall stops and grants a longer counterattack window")
	game.setup_preview("ending")
	Input.action_press("interact")
	game._process(0.01)
	Input.action_release("interact")
	check(game.state == "ending" and game.perfume_spray > 0 and game.parcel_opened, "The opened perfume can be sprayed without leaving the birthday ending")
	game.start_boss(0)
	check(game.perfume_spray == 0 and not game.journal_open, "Starting again clears perfume and journal UI state")
	finish_dialogue()

func test_radio_bridge() -> void:
	game.start_boss(1, false)
	game.player = Vector2(240, 160)
	game.state = "beach"
	game.update_attacks(0.01)
	check(game.player_hp == 100, "Fishing on the original beach does not activate the battle's lava")
	game.state = "fight"
	game.update_attacks(0.01)
	check(game.player_hp == 88 and game.state == "fight", "Stepping into exposed lava hurts without an instant death")
	game.update_attacks(0.01)
	check(game.player_hp == 88, "Lava respects damage immunity instead of draining health every frame")
	game.update_player(0.71)
	game.update_attacks(0.01)
	check(game.player_hp == 76, "Remaining in lava causes another burn after immunity expires")
	game.start_boss(1, false)
	game.player = Vector2(175, 190)
	Input.action_press("right")
	for i in range(85):
		game.update_player(1.0 / 60)
		game.update_attacks(1.0 / 60)
	Input.action_release("right")
	check(game.player.x > game.WHALE_LAVA.end.x and game.player_hp == 100, "The radio bridge permits walking across the full lava channel without burns")
	game.player = Vector2(240, 160)
	game.try_dash()
	game.update_attacks(0.01)
	check(game.player_hp == 100 and game.counter_time == 0, "A dash can avoid a burn without farming counterattack rewards from lava")
	game.start_boss(0, false)
	game.player = Vector2(240, 160)
	game.update_attacks(0.01)
	check(game.player_hp == 100, "The lava hazard does not affect other boss arenas")
	game.start_boss(1, false)
	game.player = Vector2(240, 160)
	game.player_hp = 12
	game.update_attacks(0.01)
	check(game.state == "dead", "A fatal lava burn uses the existing three-choice revival menu")
	game.choose_death_option(0)
	game.update_attacks(0.01)
	check(game.state == "fight" and game.player_hp == 100, "Revival returns the player to a safe bank rather than the lava")
	game.start_boss(0)
	finish_dialogue()

func test_death_choices() -> void:
	game.start_boss(0, false)
	game.hurt_player(100)
	check(game.state == "dead" and game.death_selection == 0, "Death opens Gaoshen's three-choice revival menu with Yes selected")
	var hover = InputEventMouseMotion.new()
	hover.position = game.DEATH_BUTTONS[1].get_center()
	game._input(hover)
	check(game.death_selection == 1, "The death menu supports mouse hover selection")
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = hover.position
	game._input(click)
	var timer: float = game.boss_timer
	game._process(1.0)
	check(game.state == "dead" and game.player_hp == 0 and game.boss_timer == timer and not game.death_message.is_empty(), "No leaves the fight frozen and gives feedback instead of reviving automatically")
	click.position = game.DEATH_BUTTONS[0].get_center()
	game._input(click)
	check(game.state == "fight" and game.player_hp == 100 and game.boss_hp == game.boss_max_hp, "Yes revives the player and restarts the current boss without a story replay")
	game.hurt_player(100)
	var key = InputEventKey.new()
	key.physical_keycode = KEY_DOWN
	key.pressed = true
	game._input(key)
	check(game.death_selection == 1, "Arrow keys move between the revival options")
	key.physical_keycode = KEY_3
	game._input(key)
	check(game.state == "upgrading" and game.player_hp == 0, "The number-three shortcut starts the upgrade animation before reviving")
	timer = game.boss_timer
	game._process(1.0)
	check(game.state == "upgrading" and game.boss_timer == timer and game.player_hp == 0, "Boss attacks and health stay frozen while the upgrade animation plays")
	game._process(game.UPGRADE_DURATION)
	check(game.state == "fight" and game.player_max_hp == 150 and game.player_hp == 150 and game.boosted_boss == game.boss_index, "Completing the animation revives Lingzhi with 150 maximum health for the current boss")
	check(not game.music.playing or game.music.stream_paused, "Finishing the upgrade keeps muted background music silent")
	game.player = game.boss - Vector2(25, 0)
	game.boss_phase = "recover"
	var hp: float = game.boss_hp
	game.try_attack()
	check(game.boss_hp == hp - 15, "Gaoshen's upgrade increases actual attack damage by fifty percent")
	game.player_hp = 140
	game.try_heal()
	check(game.player_hp == 150 and game.heal_charges == 0, "Supplies respect the upgraded maximum health")
	game.invulnerable = 0
	game.hurt_player(150)
	game.choose_death_option(0)
	check(game.player_hp == 150 and game.boosted_boss == game.boss_index, "The current chapter's upgrade survives ordinary death and revival")
	game.hurt_player(150)
	game.choose_death_option(2)
	game.update_upgrade(game.UPGRADE_DURATION)
	check(game.player_max_hp == 150, "Repeated upgrade requests replay the animation without stacking health bonuses")
	game.start_boss(1)
	check(game.player_max_hp == 100 and game.boosted_boss == -1 and game.state == "beach", "Moving to another chapter clears Gaoshen's temporary upgrade")
	game.choose_death_option(2)
	check(game.state == "beach", "Revival options cannot activate an upgrade while the player is alive")
	game.start_boss(0)
	finish_dialogue()

func press_key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._input(event)

func test_expansion() -> void:
	game.practice_mode = false
	game.difficulty = 0
	game.start_boss(0)
	finish_dialogue()
	game.hurt_player(20)
	check(game.player_hp == 88 and game.boss_max_hp == 136 and game.heal_charges == 2, "Relaxed difficulty reduces damage and boss health and supplies a second heal")
	game.boss_timer = 0
	game.update_boss(0)
	check(game.boss_timer > 0.78, "Relaxed difficulty gives longer attack warnings")
	game.difficulty = 2
	game.start_boss(0)
	finish_dialogue()
	game.hurt_player(20)
	check(game.player_hp == 75 and game.boss_max_hp == 200 and game.heal_charges == 1, "Challenge difficulty changes actual combat values")
	game.difficulty = 1
	game.start_boss(0)
	finish_dialogue()
	check(not game.try_mechanism() and not game.mechanism_used, "Arena controls require the player to approach them")
	game.player = game.Story.MECHANISMS[0].pos
	game.boss_phase = "windup"
	check(game.try_mechanism() and game.boss_phase == "recover" and game.boss_timer > 2, "The cinema remote interrupts an attack and creates a counterattack opening")
	check(not game.try_mechanism(), "A battle's mechanism cannot be activated twice")
	game.start_boss(1, false)
	game.player = game.Story.MECHANISMS[1].pos
	game.boss_phase = "airborne"
	game.boss_target = Vector2(300, 180)
	game.try_mechanism()
	check(game.lure_armed and game.boss_target == Vector2(300, 180), "Radio bait never changes an already airborne whale's warned landing point")
	game.target_whale_slam()
	check(not game.lure_armed and game.boss_target == game.RADIO_BRIDGE.get_center(), "The next whale slam consumes the radio bait and targets the bridge")
	game.start_boss(game.COW_BOSS, false)
	game.player = game.Story.MECHANISMS[2].pos
	check(not game.try_mechanism() and not game.mechanism_used, "The refund control is not wasted when no envelopes are falling")
	game.player_hp = 70
	game.boss_pattern = 4
	game.perform_boss_attack()
	check(game.try_mechanism() and game.red_packets.is_empty() and game.player_hp == 85, "Refunding the cow's envelope rain clears hazards and restores health")
	game.start_boss(3, false)
	game.player = game.Story.MECHANISMS[3].pos
	game.try_mechanism()
	game.projectiles.append({"p": game.player, "v": Vector2.LEFT * 80, "life": 3.0})
	game.update_attacks(0)
	check(game.reflect_time > 0 and game.projectiles[0].friendly and game.player_hp == 100, "The reflection panel turns a nearby hostile projectile friendly before it hits")
	game.projectiles[0].p = game.boss
	var health: float = game.boss_hp
	game.update_attacks(0)
	check(game.boss_hp == health - 18 and game.projectiles.is_empty(), "A reflected projectile damages David and is consumed")
	game.projectiles.append({"p": game.boss, "v": Vector2.ZERO, "life": 1.0, "friendly": true})
	game.boss_hp = 1
	game.update_attacks(0)
	check(game.state == "dialogue" and game.projectiles.is_empty(), "A reflected finishing blow safely exits the hazard loop")
	game.start_boss(1, false)
	game.state = "reeling"
	game.reel_time = 0
	game.reel_hits = 0
	game.reel_misses = 0
	game.reel_lock = 0
	for i in range(3):
		game.reel_lock = 0
		game.attempt_reel()
	check(game.reel_window() == 0.5 and game.reel_hits == 0, "Repeated reeling misses widen the green zone until the challenge is fully forgiving")
	game.reel_lock = 0
	game.attempt_reel()
	game.attempt_reel()
	check(game.reel_hits == 1 and game.state == "reeling", "Rapid repeated inputs cannot count as two successful reel beats")
	game.reel_lock = 0
	game.attempt_reel()
	check(game.state == "fished", "The forgiving reel challenge still leads to the whale reveal")
	game.start_boss(1, false)
	game.state = "route"
	game.player = game.SUPPORT_SPOT
	game.interact()
	game.submit_sidequest()
	check(game.state == "sidequest" and not game.sidequest_message.is_empty(), "An incorrect radio frequency gives a clue without blocking or damaging the player")
	for i in range(6): press_key(KEY_RIGHT)
	press_key(KEY_E)
	check(game.state == "support", "Tuning FM 100.6 through actual menu inputs unlocks support selection")
	press_key(KEY_ENTER)
	check(game.state == "route" and game.pending_perk == 0 and game.sidequest_done, "Selecting a support pack reserves it for the next battle")
	game.interact()
	check(game.state == "route", "A claimed support station cannot grant duplicate rewards")
	game.player = game.ROUTE_EXIT
	game.interact()
	finish_dialogue()
	check(game.active_perk == 0 and game.heal_charges == 2 and game.pending_perk == -1, "The next boss receives the selected extra heal exactly once")
	game.hurt_player(100)
	game.choose_death_option(0)
	check(game.active_perk == 0 and game.heal_charges == 2, "Ordinary death and revival preserve the chapter's support choice")
	game.state = "route"
	game.player = game.SUPPORT_SPOT
	game.interact()
	game.submit_sidequest()
	check(game.state == "sidequest", "The wrong parcel name does not grant support")
	press_key(KEY_RIGHT)
	press_key(KEY_ENTER)
	press_key(KEY_DOWN)
	press_key(KEY_ENTER)
	game.player = game.ROUTE_EXIT
	game.interact()
	finish_dialogue()
	game.try_dash()
	check(game.active_perk == 1 and game.dash_cd < 0.6, "The parcel task and shoe selection reduce the next battle's real dash cooldown")
	game.pending_perk = 2
	game.start_boss(0, false)
	game.player = game.boss - Vector2(25, 0)
	game.boss_phase = "recover"
	game.counter_time = 1
	health = game.boss_hp
	game.try_attack()
	check(game.boss_hp == health - 30, "The counter badge increases successful counterattack damage")
	game.begin_story()
	check(game.active_perk == -1 and game.pending_perk == -1, "Starting a new story clears temporary support builds")
	finish_dialogue()

func test_practice_and_save() -> void:
	game.checkpoint = 2
	game.checkpoint_perk = 1
	var cleared: int = game.cleared_bosses
	game.best_times.fill(0.0)
	game.open_practice()
	press_key(KEY_DOWN)
	check(game.practice_selection == 2, "Vertical practice selection moves to the matching grid column")
	game.practice_selection = 0
	press_key(KEY_ENTER)
	check(game.practice_mode and game.state == "fight" and game.checkpoint == 2 and game.checkpoint_perk == 1, "Practice starts without overwriting the story checkpoint or its equipment")
	game.fight_elapsed = 12.3
	game.hit_boss(10000)
	check(game.state == "practice_result" and game.new_record and is_equal_approx(game.best_times[4], 12.3), "A practice victory records its time under the selected difficulty")
	check(game.checkpoint == 2 and game.cleared_bosses == cleared, "A practice victory leaves story progression unchanged")
	press_key(KEY_R)
	game.fight_elapsed = 20
	game.hit_boss(10000)
	check(not game.new_record and is_equal_approx(game.best_times[4], 12.3), "A slower practice clear cannot replace a better record")
	press_key(KEY_R)
	game.boosted_boss = game.boss_index
	game.fight_elapsed = 5
	game.hit_boss(10000)
	check(not game.new_record and is_equal_approx(game.best_times[4], 12.3), "An upgraded practice clear cannot overwrite an ordinary record")
	game.difficulty = 0
	game.start_practice(0)
	game.fight_elapsed = 10
	game.hit_boss(10000)
	check(game.best_times[0] == 10 and is_equal_approx(game.best_times[4], 12.3), "Different difficulties keep separate best times")
	press_key(KEY_ESCAPE)
	game._process(0)
	game.difficulty = 1
	game.begin_story(true)
	check(not game.practice_mode and game.boss_index == 2 and game.active_perk == 1, "Returning from practice resumes the saved story chapter and its support")
	var original_path: String = game.save_path
	game.save_path = "/tmp/david-die-test-%d.cfg" % OS.get_process_id()
	game.saving_enabled = true
	game.checkpoint = 2
	game.active_perk = 1
	game.difficulty = 2
	game.save_checkpoint()
	game.checkpoint = 0
	game.checkpoint_perk = -1
	game.difficulty = 0
	game.best_times.fill(0.0)
	game.load_checkpoint()
	check(game.checkpoint == 2 and game.checkpoint_perk == 1 and game.difficulty == 2 and is_equal_approx(game.best_times[4], 12.3), "Saving and reloading restores the story, difficulty, support and practice records")
	DirAccess.remove_absolute(game.save_path)
	game.saving_enabled = false
	game.save_path = original_path
	game.difficulty = 1
	game.begin_story()
	finish_dialogue()
