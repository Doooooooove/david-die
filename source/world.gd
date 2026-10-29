extends Node2D

var game: Node
const INK = Color("10151d")
const GOLD = Color("e5c365")
const RED = Color("c95054")
const PLAYER = [
	"....hhhhhh......", "...hhhhhhhh.....", "...hhsssshh.....", "...hsggsggh.....",
	"...hsggsggh.....", "....ssssss......", ".....srrs.......", "...yyyyyyyy.....",
	"..yykyyykyyy....", "..sykyyykyys....", "..sykyyykyys....", "..s.yyyyyy.s....",
	"....yyyyyy......", "....kkkkkk......", "....yy..yy......", "....yy..yy......",
	"....yy..yy......", "....kk..kk......", "...kkk..kkk....."
]
const AGENT = [
	"....hhhhhh......", "...hhhhhhhh.....", "...hhsssshh.....", "....sggsgg......",
	"....sggsgg......", "....ssssss......", ".....srrs.......", "...cccccccc.....",
	"..cckccckccc....", "..sckccckccs....", "..sckccckccs....", "..s.cccccc.s....",
	"....cccccc......", "....kkkkkk......", "....cc..cc......", "....cc..cc......",
	"....cc..cc......", "....kk..kk......", "...kkk..kkk....."
]
const COW = [
	"..bb..........bb....", "..ww..........ww....", ".wwww..wwww..wwww...", "..wwwwwwwwwwwwww....",
	"...wwkkwwwwkkww.....", "...wwwkkkkkkwww.....", "...wwwgwwwwgwww.....", "...wwwwwwwwwwww.....",
	"....wppppppppw......", "....ppkppkpppp......", ".....pppppppp.......", "....kkkrkkk.........",
	"..kkkkkrkkkkk.......", "..wwkkkrkkkww.......", "..wwkkkrkkkww.......", "..wwkkkkkkkww.......",
	"....kkkkkkk.........", "....kk...kk.........", "....kk...kk.........", "....ww...ww.........",
	"...kkkk.kkkk........"
]
# Pixel silhouette sampled from DeepSeek-LLM/images/logo.svg (official whale mark).
const WHALE = [
	"...........................b............",
	"................bbbbb......bb...........",
	".......bbbbbbbbbbbbb.......bbb..........",
	".....bbbbbbbbbbbbbbb.......bbbb.......bb",
	"....bbbbbbbbbbbbbbbbb......bbbbb..bbbbbb",
	"...bbbbbbbbbbbbbbbbbbb.....bbbbbbbbbbbbb",
	"..bbbbbbbbbbbbbbbbbbbbb....bbbbbbbbbbbb.",
	"..bbbbbbbbbbbbbbbbbbbbbb....bbbbbbbbbbb.",
	".bbbbbbbbbbbbbbbbbbbbbbbb....bbbbbbbbb..",
	".bbbbbbbbbbbbbbbbbbbbbbbbb....bbbbbb....",
	"bbbbbbbbbbbbbbbbbbbbbbbbbbb...bbbb......",
	"bbb......bbbbbbbbbbbbbbbbbbbbbbbbb......",
	"bbb........bbbbbbbbbb..bbbbbbbbbbb......",
	"bbb..........bbbbbbbbb...bbbbbbbb.......",
	"bbb...........bbbbbbbbb..bbbbbbbb.......",
	"bbb............bbbbbbbb...bbbbbbb.......",
	"bbbb............bbbbbbb...bbbbbbb.......",
	"bbbb.............bbbbbbbbbbbbbbb........",
	".bbb.............bbbbbbbbbbbbbbb........",
	".bbbb.............bbbbbbbbbbbbb.........",
	".bbbbb.............bbbbbbbbbbbb.........",
	"..bbbb.............bbbbbbbbbbb..........",
	"..bbbbb......bb.....bbbbbbbbb...........",
	"...bbbbb.....bbbb....bbbbbbb............",
	"....bbbbb.....bbbb....bbbbbbb...........",
	".....bbbbbbb.bbbbbb....bbbbbbbb.........",
	"......bbbbbbbbbbbbbbbb.bbbbbbbbb........",
	".......bbbbbbbbbbbbbbbbb....bb..........",
	".........bbbbbbbbbbbbb..................",
	"............bbbbbbbb...................."
]

func rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x), floorf(y), w, h), color)

func label(text: String, x: float, y: float, size = 8, color = GOLD) -> void:
	draw_string(game.font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if game.state == "title":
		draw_title()
		return
	var scene = game.state
	if scene == "paused": scene = game.previous_state
	if scene == "dialogue":
		if game.dialogue_next == "hospital": scene = "hospital"
		elif game.dialogue_next == "street": scene = "fight"
	if scene in ["street", "glasses"]:
		draw_street()
	elif scene in ["hospital", "ct"]:
		draw_hospital()
	elif scene == "route":
		draw_route()
	elif scene in ["darkroom", "illuminate", "birthday_reveal", "birthday", "parcel_opening", "ending"]:
		draw_darkroom()
	else:
		draw_arena()
	if scene in ["fight", "dead"] or (scene == "dialogue" and game.dialogue_next == "fight"):
		draw_mechanism()
	for stain in game.stains:
		draw_rect(Rect2(stain.p, stain.size), Color("77333d"))
	for wave in game.waves:
		draw_arc(wave.p, wave.radius, 0, TAU, 52, Color("c27cbb"), 3)
		draw_arc(wave.p, maxf(1, wave.radius - 4), 0, TAU, 52, Color("703b69"), 1)
	for packet in game.red_packets:
		draw_red_packet(packet)
	if scene in ["fight", "dead", "letter_pickup", "letter", "aftermath", "dialogue"] and game.dialogue_next != "hospital":
		if game.boss_hp > 0:
			draw_tell()
			if game.boss_index == game.COW_BOSS and game.boss_phase == "charge":
				draw_line(game.boss, game.boss - game.boss_dir * 45, Color(0.95, 0.2, 0.24, 0.35), 19)
				draw_line(game.boss, game.boss - game.boss_dir * 61, Color(0.95, 0.2, 0.24, 0.16), 10)
			if game.boss_index == 1:
				var airborne = game.boss_phase == "airborne"
				var flight = clampf(1.0 - game.boss_timer, 0, 1) if airborne else 0.0
				var ground = game.boss.lerp(game.boss_target, flight) if airborne else game.boss
				draw_whale(ground, game.boss_flash > 0, sin(flight * PI) * 65)
			else:
				draw_actor(game.boss, "cow" if game.boss_index == game.COW_BOSS else "agent", game.Story.BOSSES[game.boss_index].color, game.boss_phase == "approach", game.boss_flash > 0, game.boss.x > game.player.x)
			if game.boss_phase == "recover":
				rect(game.boss.x - 2, game.boss.y - 36, 4, 4, GOLD)
		else:
			draw_corpse()
	if scene == "ct":
		draw_actor(Vector2(325, 161), "player", "e5c365")
	else:
		if not (game.invulnerable > 0 and int(game.clock * 18) % 2 == 0):
			draw_actor(game.player, "player", "e5c365", game.move_dir.length() > 0, game.hurt_flash > 0, game.facing.x < 0)
	if scene in ["beach", "fishing", "reeling", "fished"]:
		draw_fishing(scene)
	if scene == "fight" and game.reflect_time > 0:
		draw_arc(game.player - Vector2(0, 10), 27, -PI * 0.8, PI * 0.8, 32, Color("93e8dc"), 2)
		label("退件 %.1f" % game.reflect_time, game.player.x - 16, game.player.y - 43, 7, Color("b5f3e6"))
	if game.slash_time > 0 and scene == "fight":
		var angle = game.facing.angle()
		var center = game.player - Vector2(0, 10)
		var radius = 42 if game.combo_step == 3 else 31
		draw_arc(center, radius, angle - 0.95, angle + 0.95, 12, GOLD, 6 if game.combo_step == 3 else 4)
		draw_arc(center, radius + 5, angle - 0.75, angle + 0.75, 12, Color("f1edc7"), 2)
	for shot in game.projectiles:
		draw_line(shot.p, shot.p - shot.v.normalized() * 8, Color("83e2d1") if shot.get("friendly", false) else Color("b04b54"), 3)
		rect(shot.p.x - 2, shot.p.y - 2, 4, 4, Color("ddfff4") if shot.get("friendly", false) else GOLD)
	for particle in game.particles:
		if particle.has("text"):
			label(particle.text, particle.p.x + 1, particle.p.y + 1, 9, INK)
			label(particle.text, particle.p.x, particle.p.y, 9, particle.color)
		elif particle.get("ring", false):
			draw_arc(particle.p, (0.26 - particle.life) * 200, 0, TAU, 24, particle.color, 3)
		else:
			rect(particle.p.x, particle.p.y, 2, 2, particle.color)
	if scene == "route":
		prompt(game.ROUTE_EXIT, "E 进入档案室" if game.boss_index == 1 else "E 进入 04 号仓库")
		if not game.sidequest_done and game.player.distance_to(game.SUPPORT_SPOT) < 42:
			prompt(game.SUPPORT_SPOT, "E 调频求支援" if game.boss_index == 1 else "E 查收支援箱")
	if scene == "fight" and not game.mechanism_used and game.player.distance_to(game.Story.MECHANISMS[game.boss_index].pos) < 42:
		prompt(game.Story.MECHANISMS[game.boss_index].pos, "E " + game.Story.MECHANISMS[game.boss_index].name)
	if scene == "birthday" and not game.parcel_opened:
		prompt(game.BIRTHDAY_PARCEL, "E 打开快递")
	if scene == "letter_pickup":
		draw_letter_drop()
	if scene == "aftermath":
		prompt(game.DARK_DOOR, "E 进入暗室")
	if scene == "darkroom":
		prompt(game.LETTER_TABLE if game.has_special_light else game.LIGHT_STAND, "E 放下信" if game.has_special_light else "E 拿起特殊光源")
	if scene == "street" and game.pad_dropped and not game.pad_fixed:
		draw_pad_drop()
	if scene == "hospital":
		if game.scanned:
			prompt(Vector2(433, 198), "E 离开医院")
		elif game.doctor_spoken:
			prompt(Vector2(325, 143), "E 做 CT")
		else:
			prompt(Vector2(139, 131), "E 找医生")

func draw_actor(pos: Vector2, kind: String, coat: String, walking = false, flash = false, flip = false, rotation_angle = 0.0) -> void:
	var step = 1 if walking and int(game.clock * 9) % 2 == 0 else 0
	var rows = COW if kind == "cow" else (PLAYER if kind == "player" else AGENT)
	var colors = {"h": Color("24222d"), "s": Color("d5a58b"), "g": Color("181c26"), "r": Color("b84750"), "y": GOLD, "k": Color("262b37"), "c": Color(coat), "b": Color("bdb09a"), "w": Color("e0e4d5"), "p": Color("bd9291")}
	if kind == "player":
		colors.g = Color("7cc5c5")
	if kind == "cow" and game.boss_phase == "charge":
		colors.w = Color("f06462")
		colors.p = Color("cf434b")
	draw_ellipse_shadow(pos, 13 if kind == "cow" else 10)
	draw_set_transform(pos.round() + Vector2(0, step), rotation_angle, Vector2(1.5, 1.5))
	var width = rows[0].length()
	for y in range(rows.size()):
		for x in range(rows[y].length()):
			var pixel = rows[y][x]
			if pixel == ".": continue
			var px = width - x - 1 if flip else x
			var leg_offset = step if y > rows.size() - 6 and x < width / 2 else 0
			rect(px - width / 2, y - rows.size() - leg_offset, 1, 1, Color("f2eacc") if flash else colors[pixel])
	var scene = game.previous_state if game.state == "paused" else game.state
	if kind == "player" and scene not in ["ct", "beach", "fishing", "reeling", "fished", "darkroom", "illuminate", "birthday_reveal", "birthday", "parcel_opening", "ending"]:
		var side = -1 if flip else 1
		rect(side * 8, -15, 2, 13, Color("cbd8d3"))
		rect(side * 8 - 2, -7, 6, 2, GOLD)
		rect(side * 8, -4, 2, 4, RED)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(pos: Vector2, width: float) -> void:
	rect(pos.x - width, pos.y - 2, width * 2, 4, Color(0.02, 0.025, 0.04, 0.4))
	rect(pos.x - width + 3, pos.y - 4, width * 2 - 6, 7, Color(0.02, 0.025, 0.04, 0.25))

func draw_arena() -> void:
	if game.boss_index == 1:
		draw_beach()
		var scene = game.previous_state if game.state == "paused" else game.state
		if scene not in ["beach", "fishing", "reeling", "fished"]:
			draw_radio_bridge()
		return
	var palettes = [
		["211f27", "302c32", "3b3034", "876349"],
		["182833", "243945", "26333f", "4b7380"],
		["1f302e", "2b3d3b", "33423e", "688f81"],
		["301e2a", "3f2c35", "422c35", "9d5c63"]
	]
	var pal = palettes[game.boss_index]
	rect(0, 0, 480, 270, Color("0c121b"))
	rect(16, 41, 448, 193, Color(pal[0]))
	rect(21, 93, 438, 137, Color(pal[1]))
	for y in range(94, 230, 17):
		for x in range(22, 459, 25):
			rect(x, y, minf(24, 459 - x), 16, Color(pal[2]))
			rect(x + 3, y + 1, minf(19, 459 - x - 3), 1, Color(pal[1]).lightened(0.07))
	for x in range(27, 454, 46):
		rect(x, 48, 3, 43, Color(pal[3]).darkened(0.52))
		rect(x + 3, 48, 32, 39, Color(pal[0]).lightened(0.04))
	rect(20, 90, 440, 4, Color(pal[3]))
	rect(18, 229, 444, 4, Color(pal[0]).darkened(0.3))
	rect(18, 233, 444, 3, Color("0c121b"))
	# A framed combat floor keeps attacks readable against the pixel scenery.
	rect(79, 116, 326, 1, Color(pal[3]).darkened(0.4))
	rect(79, 215, 326, 1, Color(pal[3]).darkened(0.4))
	for x in [79, 404]: rect(x, 116, 1, 100, Color(pal[3]).darkened(0.4))
	match game.boss_index:
		0: draw_cinema()
		2: draw_archive()
		3: draw_final_room()
	if game.boss_index == game.FINAL_BOSS and game.state in ["letter_pickup", "aftermath", "letter"]:
		rect(411, 73, 30, 41, Color("080a12"))
		draw_rect(Rect2(411, 73, 30, 41), Color("716080"), false, 1)
		rect(434, 94, 2, 3, Color("b08ecd"))
		label("暗室", 416, 69, 7, Color("b3a0c1"))
	wall_lamp(52, 65, Color(pal[3]))
	wall_lamp(429, 65, Color(pal[3]))
	label(game.Story.BOSSES[game.boss_index].place, 27, 250, 7, Color("5d646d"))

func wall_lamp(x: float, y: float, color: Color) -> void:
	rect(x - 8, y - 9, 17, 23, Color(color, 0.07))
	rect(x - 5, y - 6, 11, 17, Color(color, 0.13))
	rect(x - 3, y - 3, 7, 9, color)
	rect(x - 2, y - 2, 5, 7, color.lightened(0.3))

func draw_mechanism() -> void:
	var p: Vector2 = game.Story.MECHANISMS[game.boss_index].pos
	var color = Color("52666a") if game.mechanism_used else Color("8ed9c7")
	if game.boss_index == 1:
		draw_radio(p - Vector2(14, 18), true)
		if game.lure_armed:
			draw_arc(p - Vector2(0, 10), 23 + sin(game.clock * 5) * 3, -PI, 0, 16, color, 1)
	else:
		rect(p.x - 12, p.y - 26, 24, 25, Color("30454c"))
		rect(p.x - 9, p.y - 23, 18, 13, color)
		rect(p.x - 8, p.y - 8, 4, 3, GOLD)
		rect(p.x + 4, p.y - 8, 4, 3, color)
		if game.boss_index == 0:
			for x in [-4, 2]: rect(p.x + x, p.y - 21, 3, 9, Color("30454c"))
		elif game.boss_index == game.COW_BOSS:
			rect(p.x - 5, p.y - 21, 10, 9, RED)
			rect(p.x - 4, p.y - 17, 8, 2, GOLD)
		else:
			draw_line(p + Vector2(-6, -21), p + Vector2(6, -13), Color("f4fff5"), 2)
	label("已用" if game.mechanism_used else "E 机关", p.x - 12, p.y + 10, 6, color)

func draw_cinema() -> void:
	rect(176, 43, 132, 53, Color("131a23"))
	rect(182, 47, 120, 43, Color("71622f"))
	rect(186, 50, 112, 36, Color("d8b850"))
	rect(186, 81, 112, 5, Color("b23342"))
	label("KILL BILL", 210, 72, 15, Color("22202a"))
	for i in range(9): rect(186, 51 + i * 4, 112, 1, Color(0, 0, 0, 0.09))
	rect(234, 96, 17, 4, Color("131a23"))
	rect(315, 75, 57, 21, Color("693e3e"))
	rect(319, 80, 20, 14, Color("84504a"))
	rect(345, 80, 23, 14, Color("84504a"))
	rect(312, 84, 5, 14, Color("4e3339"))
	rect(371, 84, 5, 14, Color("4e3339"))
	poster(89, 48, "01", Color("cfad5d"))
	plant(410, 101)
	rect(119, 202, 25, 9, Color("513a37"))
	rect(121, 200, 22, 3, Color("80614a"))
	rect(128, 195, 4, 5, PAPER_COLOR())

func PAPER_COLOR() -> Color:
	return Color("d5d0b8")

func poster(x: int, y: int, title: String, color: Color) -> void:
	rect(x - 2, y - 2, 28, 39, Color("141922"))
	rect(x, y, 24, 35, color)
	rect(x + 4, y + 5, 16, 3, Color("27212a"))
	label(title, x + 3, y + 27, 13, Color("27212a"))

func plant(x: int, y: int) -> void:
	rect(x - 5, y - 5, 12, 8, Color("866951"))
	rect(x - 2, y - 23, 3, 19, Color("4b7160"))
	rect(x - 10, y - 21, 9, 5, Color("496c58"))
	rect(x + 1, y - 18, 9, 5, Color("5a8264"))
	rect(x - 5, y - 28, 7, 9, Color("608b68"))

func draw_beach() -> void:
	rect(0, 0, 480, 270, Color("10222e"))
	rect(18, 42, 444, 190, Color("d9c398"))
	rect(18, 42, 444, 29, Color("b6d4d6"))
	rect(18, 71, 444, 62, Color("428c9d"))
	rect(18, 92, 444, 41, Color("55a6ad"))
	rect(18, 116, 444, 22, Color("80bfc0"))
	for i in range(25):
		var x = 26 + fposmod(i * 63.0 + game.clock * 9, 416)
		var y = 80 + (i % 4) * 13
		rect(x, y, 8 + i % 11, 1, Color("acd9d2"))
	for x in range(18, 462, 16):
		var edge = 136 + int(sin(x * 0.06 + game.clock * 1.8) * 3)
		rect(x, edge, mini(16, 462 - x), 5, Color("d5e7d5"))
		rect(x, edge + 5, mini(16, 462 - x), 5, Color("bdcbb0"))
	for i in range(48):
		var x = 25 + fposmod(i * 73.0, 428)
		var y = 159 + fposmod(i * 17.0, 66)
		rect(x, y, 2 + i % 3, 1, Color("baa77e"))
	rect(391, 61, 17, 8, Color("eee6be"))
	rect(387, 64, 25, 3, Color("eee6be"))
	rect(41, 170, 4, 39, Color("75654e"))
	rect(43, 166, 6, 15, Color("5b826d"))
	rect(35, 169, 6, 12, Color("71957a"))
	rect(411, 205, 19, 4, Color("a38e70"))
	rect(415, 201, 12, 4, Color("b7a284"))
	label("海边 / THE QUIET SHORE", 27, 250, 7, Color("6a8c94"))
	var scene = game.previous_state if game.state == "paused" else game.state
	if scene in ["beach", "fishing", "fished"]:
		var spot = game.FISHING_SPOT
		draw_arc(spot, 12, 0, TAU, 16, Color("f6e5ae"), 1)
		label("钓鱼点", spot.x - 11, spot.y + 20, 6, Color("786f59"))
		if not game.has_fishing_rod:
			var rod = game.FISHING_ROD
			draw_line(rod + Vector2(-10, 4), rod + Vector2(12, -18), Color("77563e"), 2)
			draw_line(rod + Vector2(12, -18), rod + Vector2(18, -2), Color("fff2d0"), 1)
			rect(rod.x - 4, rod.y - 4, 4, 4, GOLD)
			prompt(rod, "E 拿起鱼竿")
		elif scene == "beach":
			prompt(spot, "E 抛竿")

func draw_radio_bridge() -> void:
	var lava: Rect2 = game.WHALE_LAVA
	var bridge: Rect2 = game.RADIO_BRIDGE
	# The orange channel crosses the whole combat floor; only the radios are safe.
	rect(lava.position.x - 7, lava.position.y, lava.size.x + 14, lava.size.y, Color("73504c"))
	draw_rect(lava, Color("b93432"))
	for row in range(15):
		var y = lava.position.y + row * 6
		var shift = int(sin(game.clock * 1.6 + row * 0.9) * 6)
		rect(lava.position.x + 5 + abs(shift), y, lava.size.x - 10 - abs(shift) * 2, 3, Color("ec6338") if row % 3 else Color("ffad46"))
	for i in range(14):
		var x = lava.position.x + 7 + fposmod(i * 31.0, lava.size.x - 14)
		var y = lava.end.y - fposmod(i * 19.0 + game.clock * 12, lava.size.y)
		rect(x, y, 2, 2, Color("ffd279"))
	for x in [lava.position.x - 7, lava.end.x]:
		for y in range(144, 232, 11):
			rect(x, y, 7, 8, Color("4f454c"))
	# Four columns of two radios form a continuous, visibly wide bridge deck.
	draw_rect(bridge.grow(2), Color("2b2835"))
	for row in range(2):
		for column in range(4):
			draw_radio(bridge.position + Vector2(column * 28, row * 18), (column + row) % 2 == 0)
	label("FM 100.6 / 收音机桥", 305, 222, 7, Color("775944"))

func draw_radio(pos: Vector2, mint: bool) -> void:
	var casing = Color("9ac8bd") if mint else Color("e5bc85")
	# Raised handle, speaker grille, tuning scale, two knobs and an aerial: 📻.
	draw_line(pos + Vector2(24, 5), pos + Vector2(27, 0), Color("dbe5dc"), 1)
	rect(pos.x + 5, pos.y + 1, 13, 4, Color("343946"))
	rect(pos.x + 7, pos.y + 2, 9, 2, Color("b9c9c0"))
	rect(pos.x, pos.y + 5, 28, 13, casing.darkened(0.3))
	rect(pos.x + 1, pos.y + 5, 26, 11, casing)
	rect(pos.x + 3, pos.y + 7, 9, 7, Color("343d48"))
	for y in range(8, 14, 2):
		rect(pos.x + 4, pos.y + y, 7, 1, Color("73838a"))
	rect(pos.x + 15, pos.y + 7, 9, 3, Color("374e54"))
	rect(pos.x + 16, pos.y + 8, 7, 1, Color("e3ebc0"))
	rect(pos.x + 20, pos.y + 7, 1, 3, Color("d2524e"))
	for x in [17, 23]:
		rect(pos.x + x, pos.y + 12, 3, 3, Color("343d48"))

func draw_whale(pos: Vector2, flash = false, height = 0.0) -> void:
	draw_ellipse_shadow(pos, 13 - height * 0.08)
	pos.y -= height
	var bob = int(sin(game.clock * 5) * 2)
	var blue = Color("4d6bfe")
	for y in range(WHALE.size()):
		for x in range(WHALE[y].length()):
			var pixel = WHALE[y][x]
			if pixel != ".":
				rect(pos.x + x - 20, pos.y + y - 34 + bob, 1, 1, Color("fff3d0") if flash else blue)

func draw_fishing(scene: String) -> void:
	if not game.has_fishing_rod:
		return
	var hand = game.player + Vector2(8, -13)
	var tip = hand + Vector2(18, -29)
	draw_line(hand, tip, Color("785740"), 2)
	rect(hand.x - 2, hand.y - 3, 4, 5, GOLD)
	if scene == "beach":
		return
	var hook = Vector2(292, 115 + sin(game.clock * 6) * 2)
	if scene == "fished":
		var progress = clampf(game.fishing_time / 0.8, 0, 1)
		hook = Vector2(292, 115).lerp(game.boss - Vector2(0, 17), progress)
		hook.y -= sin(progress * PI) * 42
		draw_whale(hook + Vector2(0, 17))
		label("DeepSeek !?", hook.x - 22, hook.y - 17, 7, Color("334b92"))
	else:
		draw_arc(hook + Vector2(0, 3), 10 + sin(game.clock * 5) * 3, 0, TAU, 20, Color("e1f0d5"), 1)
		rect(hook.x - 2, hook.y - 5, 4, 5, RED if game.fishing_time >= 1.8 else Color("faf3da"))
		if game.fishing_time >= 1.8:
			prompt(game.player + Vector2(0, -9), "咬钩了！E 收竿")
	draw_line(tip, hook, Color("fff4d7"), 1)

func draw_route() -> void:
	var pier = game.boss_index == 1
	rect(0, 0, 480, 270, Color("10222e") if pier else Color("121b24"))
	rect(18, 43, 444, 188, Color("377585") if pier else Color("263b3c"))
	if pier:
		for y in range(57, 225, 15):
			for x in range(28, 455, 41): rect(x, y, 15, 1, Color("72a8aa"))
		rect(25, 129, 430, 74, Color("826a51"))
		for x in range(28, 452, 13): rect(x, 132, 11, 68, Color("a48c68"))
		for y in [130, 199]:
			rect(25, y, 430, 3, Color("d3b98a"))
			for x in range(30, 450, 52): rect(x, y - 12, 4, 20, Color("5b5146"))
	else:
		rect(23, 128, 434, 96, Color("384c49"))
		for x in range(25, 454, 27): rect(x, 131, 1, 92, Color("48615a"))
		for x in [65, 171, 277]:
			rect(x, 55, 56, 73, Color("192a2b"))
			rect(x + 5, 60, 46, 64, Color("425953"))
			label("0%d" % (1 + (x - 65) / 106), x + 17, 93, 12, Color("a5b39a"))
		draw_parcel(Vector2(145, 197), false, "货物")
		draw_parcel(Vector2(290, 202), false, "货物")
	rect(387, 72, 64, 112, Color("1b2a2c"))
	rect(394, 79, 50, 99, Color("68867a") if pier else Color("80625e"))
	rect(433, 123, 3, 6, GOLD)
	label("1006" if pier else "04", 403, 105, 12, GOLD)
	label("货运档案室" if pier else "DAVID", 394, 67, 8, Color("c8b886"))
	label("通行牌：1006 / 沿栈道进入档案室" if pier else "货单：高申的快递 / 04 号仓库 →", 38, 218, 8, Color("ddd0a8"))
	label("海边 → 旧码头" if pier else "档案室 → 仓库走廊", 27, 250, 7, Color("7c9b99"))
	var support: Vector2 = game.SUPPORT_SPOT
	rect(support.x - 23, support.y - 6, 46, 7, Color("51666a"))
	if pier:
		draw_radio(support - Vector2(14, 25), true)
	else:
		draw_parcel(support - Vector2(0, 7), false, "支援")
	if game.sidequest_done or game.player.distance_to(support) >= 42:
		label("支援已领取" if game.sidequest_done else ("FM 100.6 / 高申在线" if pier else "可选任务 / 查收支援"), support.x - 36, support.y - 34, 7, Color("d1efcd"))

func draw_parcel(pos: Vector2, opened = false, recipient = "高申") -> void:
	rect(pos.x - 12, pos.y - 15, 25, 17, Color("b79471"))
	rect(pos.x - 10, pos.y - 13, 21, 13, Color("e0bf95"))
	rect(pos.x - 2, pos.y - 15, 4, 17, Color("f6e3c1"))
	label(recipient, pos.x - 10, pos.y - 3, 6, Color("745a47"))
	if opened:
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-12, -15), pos + Vector2(-19, -23), pos + Vector2(13, -23), pos + Vector2(13, -15)]), Color("cda77e"))
		paint_perfume(self, pos + Vector2(0, -12), 0.7)

static func paint_perfume(c: Node2D, origin: Vector2, scale: float) -> void:
	# Shared pixel bottle for the parcel close-up and the little gift on the table.
	var pieces = [
		[Rect2(-7, -34, 14, 7), "b6d9d3"], [Rect2(-6, -33, 12, 4), "e8f6ed"],
		[Rect2(-4, -27, 8, 4), "c9ad77"], [Rect2(-5, -23, 10, 2), "6eaaa8"],
		[Rect2(-10, -21, 20, 19), "77b8b7"], [Rect2(-11, -18, 22, 14), "77b8b7"],
		[Rect2(-9, -20, 18, 17), "e0f4ee"], [Rect2(-8, -12, 16, 8), "a6d9d0"],
		[Rect2(-7, -19, 2, 13), "fbfff9"], [Rect2(7, -17, 1, 11), "f5fffa"],
		[Rect2(-6, -16, 12, 8), "fffaf0"], [Rect2(-4, -14, 8, 1), "739c98"],
		[Rect2(-3, -12, 6, 1), "c4ae81"], [Rect2(-8, -3, 16, 2), "bde5dd"]
	]
	for piece in pieces:
		var shape: Rect2 = piece[0]
		c.draw_rect(Rect2(origin + shape.position * scale, shape.size * scale), Color(piece[1]))

func draw_archive() -> void:
	for x in [99, 146, 193, 286, 333, 380]:
		rect(x, 48, 33, 44, Color("4a5c55"))
		for y in [53, 65, 77]:
			rect(x + 2, y, 29, 10, Color("3a4946"))
			rect(x + 12, y + 3, 8, 2, Color("8e9c8b"))
	rect(233, 47, 41, 37, Color("13282a"))
	label("1006", 238, 65, 11, Color("91bca4"))
	rect(240, 70, 27, 2, Color("63796a"))
	rect(391, 181, 37, 20, Color("31443e"))
	for i in range(4): rect(395 + i * 6, 181 - i % 2 * 2, 5, 13, Color("a5a990"))
	for x in [62, 420]:
		rect(x, 46, 1, 14, GOLD)
		rect(x - 7, 59, 15, 18, Color("c7474f"))
		rect(x - 4, 61, 9, 14, Color("e6655a"))
		rect(x - 7, 62, 15, 2, GOLD)
		rect(x - 7, 72, 15, 2, GOLD)
		rect(x - 1, 77, 3, 9, GOLD)

func draw_red_packet(packet: Dictionary) -> void:
	var p: Vector2 = packet.p
	var remaining: float = packet.remaining
	if remaining > 0:
		draw_circle(p, 18, Color(0.9, 0.17, 0.22, 0.10))
		draw_arc(p, 18, 0, TAU, 20, RED, 1)
		draw_line(p - Vector2(4, 4), p + Vector2(4, 4), GOLD, 1)
		draw_line(p + Vector2(-4, 4), p + Vector2(4, -4), GOLD, 1)
		var height = minf(remaining * 75, 72)
		rect(p.x - 5, p.y - height - 12, 10, 14, Color("8f303f"))
		rect(p.x - 4, p.y - height - 11, 8, 12, Color("e45454"))
		draw_line(Vector2(p.x - 4, p.y - height - 10), Vector2(p.x, p.y - height - 6), GOLD, 1)
		draw_line(Vector2(p.x + 4, p.y - height - 10), Vector2(p.x, p.y - height - 6), GOLD, 1)
		rect(p.x - 1, p.y - height - 5, 3, 3, GOLD)
	else:
		draw_arc(p, 18 + -remaining * 30, 0, TAU, 20, Color(0.95, 0.6, 0.35, maxf(0, 1 + remaining * 3)), 2)

func draw_darkroom() -> void:
	var bright = game.birthday_revealed
	rect(0, 0, 480, 270, Color("fff6eb") if bright else Color("070a11"))
	rect(18, 43, 444, 188, Color("f9ece5") if bright else Color("0c101a"))
	rect(22, 95, 436, 133, Color("f1e9df") if bright else Color("111725"))
	for y in range(99, 228, 18):
		for x in range(25, 450, 25):
			rect(x, y, 23, minf(16, 228 - y), Color("f7efe4") if bright else Color("151c2b"))
	# The birthday scene is never drawn before the light puzzle is solved.
	if not game.birthday_revealed:
		rect(262, 43, 200, 187, Color("05070d"))
		rect(256, 44, 4, 184, Color("191727"))
	else:
		draw_birthday_room()
		if game.has_parcel:
			draw_parcel(game.BIRTHDAY_PARCEL, game.parcel_opened)
		for x in range(31, 246, 21):
			draw_line(Vector2(x, 55), Vector2(x + 21, 58), Color("d6bab1"), 1)
			draw_colored_polygon(PackedVector2Array([Vector2(x + 3, 56), Vector2(x + 15, 58), Vector2(x + 8, 68)]), [Color("efb5c2"), Color("b5dce3"), Color("bedbc1")][(x / 21) % 3])
	var lamp = game.LIGHT_STAND
	draw_circle(lamp - Vector2(0, 11), 30, Color(0.45, 0.25, 0.7, 0.05))
	rect(lamp.x - 10, lamp.y - 2, 22, 7, Color("c8c4d9") if bright else Color("313046"))
	if not game.has_special_light:
		rect(lamp.x - 3, lamp.y - 15, 6, 13, Color("7f698b"))
		rect(lamp.x - 4, lamp.y - 16, 8, 5, Color("bb91e4"))
		label("特殊光源", lamp.x - 18, lamp.y - 24, 6, Color("b999d4"))
	var table = game.LETTER_TABLE
	rect(table.x - 19, table.y - 12, 38, 16, Color("dcc2c4") if bright else Color("3b3449"))
	rect(table.x - 16, table.y + 4, 3, 7, Color("bba6b7") if bright else Color("292736"))
	rect(table.x + 13, table.y + 4, 3, 7, Color("bba6b7") if bright else Color("292736"))
	rect(table.x - 8, table.y - 12, 16, 9, Color("fff9e8") if bright else Color("a7a4aa"))
	if not game.birthday_revealed:
		label("把信放在这里", table.x - 24, table.y - 21, 7, Color("736c83"))

func draw_birthday_room() -> void:
	rect(264, 44, 196, 50, Color("e9f5f2"))
	rect(264, 94, 196, 134, Color("fff2e4"))
	for y in range(99, 229, 17):
		rect(267, y, 190, 1, Color("efdfcf"))
	# A large freestanding arch, built from three overlapping balloon rows.
	var palette = [Color("f4b5c4"), Color("b5dce7"), Color("c1dec4"), Color("f7dfa4"), Color("d8c6e9")]
	for x in [272, 448]:
		rect(x - 10, 198, 21, 5, Color("deded2"))
		rect(x - 7, 179, 15, 19, Color("fffdfa"))
		rect(x - 7, 179, 15, 3, Color("b8dbd3"))
	for band in range(3):
		for i in range(25):
			var angle = PI * i / 24.0
			var x = 360 + (83 + band * 5) * cos(angle)
			var y = 187 - (118 + band * 6) * sin(angle)
			balloon(Vector2(x, y), 5 + (i + band) % 3, palette[(i + band * 2) % palette.size()])
	label("HAPPY", 328, 100, 11, Color("b86f94"))
	label("BIRTHDAY", 314, 115, 11, Color("b86f94"))
	label("LINGZHI", 338, 130, 7, Color("829f9e"))
	label("20", 337, 164, 37, Color("cea358"))
	rect(315, 200, 94, 5, Color("fffdf8"))
	rect(323, 205, 5, 13, Color("d8d5ca"))
	rect(396, 205, 5, 13, Color("d8d5ca"))
	rect(340, 181, 45, 18, Color("e8a7bc"))
	rect(337, 178, 51, 7, Color("fffaf0"))
	for x in range(340, 386, 9): rect(x, 183, 4, 6, Color("fffaf0"))
	rect(342, 195, 41, 2, Color("ce8fa7"))
	for x in [350, 373]:
		rect(x, 168, 3, 10, Color("a5cfc9"))
		rect(x, 163, 3, 5, Color("e5b458"))
	for x in [290, 422]:
		var color = palette[0 if x == 290 else 1]
		rect(x - 7, 204, 18, 15, color)
		rect(x - 9, 201, 22, 4, color.lightened(0.12))
		rect(x, 201, 3, 18, Color("fff9e7"))
		rect(x - 4, 197, 5, 4, Color("d3b582"))
		rect(x + 3, 197, 5, 4, Color("d3b582"))
	label("灵芝，20 岁生日快乐！", 292, 226, 9, Color("a2768a"))
	for i in range(64):
		var x = 29 + fposmod(i * 31.7 + game.clock * (3 if i % 2 else -3), 424)
		var y = 54 + fposmod(i * 27.3 + game.clock * 19, 169)
		rect(x, y, 2, 3 if i % 2 else 2, palette[i % palette.size()].darkened(0.05))

func balloon(pos: Vector2, radius: int, color: Color) -> void:
	rect(pos.x - radius + 2, pos.y - radius, radius * 2 - 4, radius * 2, color.darkened(0.08))
	rect(pos.x - radius, pos.y - radius + 3, radius * 2, radius * 2 - 6, color.darkened(0.08))
	rect(pos.x - radius + 2, pos.y - radius + 1, radius * 2 - 4, radius * 2 - 2, color)
	rect(pos.x - radius + 1, pos.y - radius + 3, radius * 2 - 2, radius * 2 - 6, color)
	rect(pos.x - radius + 3, pos.y - radius + 3, 2, 3, color.lightened(0.4))

func draw_final_room() -> void:
	rect(160, 43, 160, 48, Color("1a1e2b"))
	for x in [163, 216, 269]:
		rect(x + 2, 45, 47, 42, Color("343647"))
		rect(x + 6, 48, 37, 32, Color("484356"))
		for i in range(5): rect(x + 7 + i * 7, 61 + i % 3 * 4, 5, 19, Color("222738"))
		rect(x + 17, 66, 2, 3, Color("cbb987"))
	rect(189, 103, 106, 115, Color("573039"))
	rect(193, 105, 98, 111, Color("64353b"))
	for x in [194, 288]: rect(x, 105, 2, 111, Color("9a6b57"))
	label("04 / DAVID", 213, 83, 9, GOLD)
	if game.boss_hp > 0 and not game.has_parcel:
		draw_parcel(Vector2(392, 197))
	plant(113, 101)
	plant(369, 101)

func draw_street() -> void:
	rect(0, 0, 480, 270, Color("101b27"))
	rect(20, 43, 440, 61, Color("23323d"))
	for x in range(25, 326, 49):
		rect(x, 51, 40, 46, Color("18232e"))
		rect(x + 5, 57, 30, 30, Color("3d4b50"))
		rect(x + 19, 57, 2, 30, Color("192631"))
		rect(x + 5, 71, 30, 2, Color("192631"))
	rect(328, 42, 133, 64, Color("536a6b"))
	rect(345, 49, 99, 18, Color("253a40"))
	label("医 院  /  HOSPITAL", 352, 61, 7, Color("c2d9c8"))
	rect(414, 73, 30, 35, Color("172b35"))
	rect(418, 75, 22, 30, Color("78a2a1"))
	rect(428, 75, 2, 30, Color("36515a"))
	rect(351, 79, 31, 21, Color("8eaaa2"))
	rect(363, 81, 6, 17, Color("d5e1c9"))
	rect(357, 87, 18, 5, Color("d5e1c9"))
	rect(20, 106, 440, 123, Color("283b47"))
	for y in range(109, 227, 17):
		for x in range(22, 458, 28):
			rect(x, y, 26, 15, Color("2e424e"))
	for x in range(42, 453, 43): rect(x, 219, 20, 2, Color("77765e"))
	for x in [102, 300]:
		rect(x, 89, 3, 52, Color("141f2a"))
		rect(x - 7, 86, 17, 4, Color("e0c382"))
		rect(x - 13, 90, 29, 8, Color(0.85, 0.71, 0.41, 0.08))
	label("医院 →", 340, 206, 10, Color("88b7ae"))
	prompt(Vector2(424, 114), "E 进入")
	label("放映室 → 医院 → 海边旧码头", 27, 250, 7, Color("5d727f"))

func draw_hospital() -> void:
	rect(0, 0, 480, 270, Color("101c27"))
	rect(18, 42, 444, 51, Color("a4b7b0"))
	rect(18, 81, 444, 13, Color("6e9890"))
	rect(18, 94, 444, 137, Color("8b9e9a"))
	for y in range(95, 230, 18):
		for x in range(20, 462, 22):
			rect(x, y, minf(21, 462 - x), minf(17, 231 - y), Color("94a8a2") if (x / 22 + y / 18) % 2 else Color("8fa39e"))
	rect(220, 42, 4, 96, Color("607e7c"))
	rect(220, 185, 4, 46, Color("607e7c"))
	label("门 诊", 112, 67, 13, Color("28494c"))
	label("CT  /  检查室", 295, 67, 12, Color("28494c"))
	rect(85, 111, 104, 20, Color("587c78"))
	rect(82, 108, 110, 7, Color("c4c8b0"))
	rect(107, 91, 22, 17, Color("273e4a"))
	rect(110, 94, 16, 10, Color("72a99e"))
	draw_actor(Vector2(145, 106), "agent", "dbe0d0")
	rect(172, 101, 12, 5, Color("e4dfc8"))
	plant(52, 101)
	for x in [50, 76, 102]:
		rect(x, 184, 22, 8, Color("547d7d"))
		rect(x + 2, 176, 18, 9, Color("678e89"))
		rect(x + 2, 192, 2, 5, Color("435d61"))
		rect(x + 18, 192, 2, 5, Color("435d61"))
	# Squared pixel donut and moving bed for the CT interaction.
	rect(292, 94, 68, 58, Color("546e75"))
	rect(288, 97, 76, 49, Color("b8c9bd"))
	rect(296, 90, 60, 62, Color("c7d0c1"))
	rect(304, 101, 44, 39, Color("6f898b"))
	rect(310, 107, 32, 28, Color("263f4a"))
	rect(316, 133, 20, 44, Color("b4c4b6"))
	rect(310, 143, 32, 25, Color("d0d4c2"))
	rect(313, 146, 26, 20, Color("8aa69b"))
	rect(312, 172, 29, 5, Color("4d7273"))
	rect(369, 111, 48, 26, Color("47646b"))
	rect(373, 114, 39, 18, Color("19353f"))
	for i in range(4): rect(378 + i * 7, 117 + (i % 2) * 2, 3, 10 - (i % 2) * 4, Color("82bbac"))
	if game.state == "ct":
		var scan_y = 110 + fposmod(game.scan_time * 12, 54)
		rect(308, scan_y, 35, 2, Color("73e0cc"))
		rect(308, scan_y - 4, 35, 9, Color(0.3, 0.9, 0.8, 0.12))
	rect(418, 185, 30, 44, Color("254d54"))
	label("EXIT", 422, 199, 7, Color("b8d1bc"))
	rect(441, 204, 3, 3, GOLD)
	label("检查结束后，从右下方出口离开。", 27, 250, 7, Color("6d888d"))

func draw_tell() -> void:
	if game.boss_index == 1 and game.boss_phase in ["windup", "airborne"]:
		var target = game.boss_target
		draw_circle(target, 26, Color(0.85, 0.2, 0.28, 0.2))
		draw_arc(target, 27, 0, TAU, 28, INK, 4)
		draw_arc(target, 26, 0, TAU, 28, RED, 2)
		if game.boss_phase == "airborne":
			draw_arc(target, 26 + clampf(game.boss_timer, 0, 1) * 20, 0, TAU, 28, Color("fff0c2"), 1)
		draw_line(target - Vector2(8, 8), target + Vector2(8, 8), GOLD, 1)
		draw_line(target + Vector2(-8, 8), target + Vector2(8, -8), GOLD, 1)
		label("!", target.x - 2, target.y - 31, 12, GOLD)
		return
	if game.boss_phase != "windup": return
	var pos = game.boss
	var alpha = 0.12 + (sin(game.clock * 23) + 1) * 0.06
	match game.boss_pattern:
		0:
			draw_circle(pos, 53, Color(0.8, 0.17, 0.23, alpha))
			draw_arc(pos, 53, 0, TAU, 48, RED, 1)
		1:
			for angle in [-0.32, 0.0, 0.32]:
				draw_line(pos, pos + game.boss_dir.rotated(angle) * 210, Color(0.85, 0.3, 0.33, alpha + 0.15), 2)
		2:
			draw_arc(pos, 65, 0, TAU, 48, Color("c27cbb"), 2)
			draw_arc(pos, 35, 0, TAU, 36, Color(0.7, 0.3, 0.5, alpha + 0.2), 1)
		3:
			var perpendicular = game.boss_dir.orthogonal() * 13
			draw_colored_polygon(PackedVector2Array([pos + perpendicular, pos - perpendicular, pos - perpendicular + game.boss_dir * 190, pos + perpendicular + game.boss_dir * 190]), Color(0.8, 0.2, 0.25, alpha))
			draw_line(pos, pos + game.boss_dir * 190, RED, 1)
		4:
			draw_arc(pos - Vector2(0, 10), 28, 0, TAU, 20, GOLD, 1)
	label("!", pos.x - 2, pos.y - 33, 12, GOLD)

func draw_corpse() -> void:
	if game.boss_index == 1:
		return
	rect(game.boss.x - 13, game.boss.y - 5, 28, 9, Color(game.Story.BOSSES[game.boss_index].color).darkened(0.2))
	rect(game.boss.x + 12, game.boss.y - 3, 7, 7, Color("b8907e"))
	if game.boss_index == game.COW_BOSS:
		rect(game.boss.x + 12, game.boss.y - 3, 7, 7, Color("d7ded6"))

func draw_pad_drop() -> void:
	var p = game.pad_pos
	var pulse = (sin(game.clock * 4) + 1) * 0.5
	draw_circle(p, 9 + pulse * 3, Color(0.9, 0.8, 0.4, 0.12))
	rect(p.x - 2, p.y - 2, 4, 5, GOLD)
	draw_line(p - Vector2(7, 0), p + Vector2(7, 0), Color("f7e3a1"), 1)
	draw_line(p - Vector2(0, 7), p + Vector2(0, 7), Color("f7e3a1"), 1)
	prompt(p, "E 鼻托")

func draw_letter_drop() -> void:
	var p = game.letter_pos + Vector2(0, sin(game.clock * 3) * 1.5)
	draw_circle(p, 13, Color(0.9, 0.8, 0.4, 0.12))
	rect(p.x - 7, p.y - 4, 14, 9, Color("e7debf"))
	draw_line(p - Vector2(7, 4), p + Vector2(0, 1), Color("aa8b68"), 1)
	draw_line(p + Vector2(7, -4), p + Vector2(0, 1), Color("aa8b68"), 1)
	draw_parcel(game.letter_pos + Vector2(20, 4))
	prompt(game.letter_pos, "E 取回快递和信")

func prompt(pos: Vector2, message: String) -> void:
	if game.player.distance_to(pos) > 45: return
	var width = game.font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10
	rect(pos.x - width / 2, pos.y - 43, width, 13, Color("101c29"))
	label(message, pos.x - width / 2 + 5, pos.y - 34, 7, GOLD)

func draw_title() -> void:
	rect(0, 0, 480, 270, Color("17232c"))
	for i in range(18):
		var x = 278 + i * 13
		var height = 39 + fposmod(i * 21, 49)
		rect(x, 95 - height, 11, height + 110, Color("1e303b"))
		for y in range(40, 173, 14):
			if (i + y) % 3: rect(x + 3, y, 2, 4, Color("766d50"))
	rect(280, 181, 200, 89, Color("263541"))
	for y in range(185, 270, 14): rect(280, y, 200, 1, Color("344451"))
	for i in range(35):
		var x = 281 + fposmod(i * 31.7 + game.clock * 4, 199)
		var y = fposmod(i * 41.3 + game.clock * 80, 260)
		draw_line(Vector2(x, y), Vector2(x - 2, y + 7), Color(0.5, 0.6, 0.7, 0.17), 1)
	draw_set_transform(Vector2(369, 185), 0, Vector2(4, 4))
	draw_actor_portrait()
	draw_set_transform(Vector2.ZERO)
	rect(318, 193, 113, 2, Color("bd4f55"))
	label("01 — 04", 350, 240, 8, Color("667984"))

func draw_actor_portrait() -> void:
	var colors = {"h": Color("24222d"), "s": Color("d5a58b"), "g": Color("7cc5c5"), "r": RED, "y": GOLD, "k": Color("262b37")}
	for y in range(PLAYER.size()):
		for x in range(PLAYER[y].length()):
			var pixel = PLAYER[y][x]
			if pixel != ".": rect(x - 8, y - 19, 1, 1, colors[pixel])
	rect(9, -17, 2, 15, Color("cbd8d3"))
	rect(7, -8, 6, 2, GOLD)
	rect(9, -5, 2, 5, RED)
