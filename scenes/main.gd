extends Node2D

const FRUIT := preload("res://scenes/fruit.tscn")
const SFX_POP := preload("res://audio/pop.wav")
const SFX_GAMEOVER := preload("res://audio/gameover.wav")

## 待機中の果物を浮かせておく高さ
const DROP_Y := 120.0
## 箱の内側の壁の X（果物の半径ぶんはこの内側に収める）
const BIN_LEFT := 110.0
const BIN_RIGHT := 610.0
## 次を落とせるまでの待ち時間（秒）
const COOLDOWN := 0.6
## 最初に出てくる果物の最大ランク（0〜これ の中からランダム）
const SPAWN_MAX_RANK := 2
## この Y より上に果物が居座ったらアウト
const LINE_Y := 210.0
## 何秒 居座り続けたらゲームオーバーにするか
const GAME_OVER_DELAY := 1.5
## ハイスコアの保存先（user:// は OS ごとのアプリ専用フォルダ）
const SAVE_PATH := "user://suika_save.cfg"
## 前の合体からこの秒数以内に次が合体したらコンボ継続
const COMBO_WINDOW := 1.2
## 合体成功時、この確率でできた玉をアイテムとしてキープする
const ITEM_DROP_CHANCE := 0.10

var current_fruit: Fruit = null
var can_drop := true
var score := 0
var high_score := 0
var next_rank := 0
var game_over := false
# 狙っている X 位置（マウス移動・タッチのドラッグで更新）
var aim_x := 360.0
# 果物がラインを超えている状態が続いている時間
var danger_time := 0.0
# 画面シェイクの残り強さ（ピクセル）
var shake := 0.0
# コンボ
var combo := 0
var last_merge_sec := -999.0
# キープ中の果物のランクのリスト（手に入れた順）。先頭から消費していく
var stock_queue: Array[int] = []

@onready var score_label: Label = $HUD/ScoreLabel
@onready var best_label: Label = $HUD/BestLabel
@onready var next_preview: PreviewIcon = $HUD/NextPreview
@onready var stock_button: StockSlot = $HUD/StockButton
@onready var danger_line: Line2D = $GameOverLine
@onready var drop_guide: Line2D = $DropGuide
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/FinalScore
@onready var go_best_label: Label = $HUD/GameOverPanel/BestLine


func _ready() -> void:
	_load_high_score()
	next_rank = randi() % (SPAWN_MAX_RANK + 1)
	next_preview.show_rank(next_rank)
	stock_button.pressed.connect(_on_stock_pressed)
	_update_score()
	_spawn_next()


func _process(delta: float) -> void:
	_update_shake(delta)
	if game_over:
		return
	if current_fruit != null:
		var r := current_fruit.radius
		current_fruit.position.x = clampf(aim_x, BIN_LEFT + r, BIN_RIGHT - r)
	_update_drop_guide()
	_check_game_over(delta)
	_update_danger_line()


# 落下ガイド線：持っている果物の真下へ薄い縦線
func _update_drop_guide() -> void:
	if current_fruit == null:
		drop_guide.visible = false
		return
	var x := current_fruit.position.x
	drop_guide.visible = true
	drop_guide.points = PackedVector2Array([
		Vector2(x, DROP_Y + current_fruit.radius),
		Vector2(x, 1150.0),
	])


func _update_shake(delta: float) -> void:
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 45.0)
		position = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	elif position != Vector2.ZERO:
		position = Vector2.ZERO


func _add_shake(amount: float) -> void:
	shake = minf(16.0, maxf(shake, amount))


# 危険ライン：果物が線を超えている間だけチカチカさせる
func _update_danger_line() -> void:
	if danger_time > 0.0:
		var a := 0.35 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.013))
		danger_line.default_color = Color(1, 0.25, 0.25, a)
		danger_line.width = 5.0
	else:
		danger_line.default_color = Color(0.9, 0.3, 0.3, 0.55)
		danger_line.width = 3.0


func _unhandled_input(event: InputEvent) -> void:
	# キーボード R はいつでもやり直し
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()
		return

	if game_over:
		# ゲームオーバー中はクリック/タップでリスタート
		var tapped: bool = (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventScreenTouch and event.pressed)
		if tapped:
			get_tree().reload_current_scene()
		return

	# --- 狙う位置の更新（マウス移動 / タッチのドラッグ）---
	if event is InputEventMouseMotion:
		aim_x = event.position.x
	elif event is InputEventScreenDrag:
		aim_x = event.position.x
	elif event is InputEventScreenTouch:
		aim_x = event.position.x
		if not event.pressed:
			_drop()  # 指を離したら落とす
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_drop()  # ボタンを離したら落とす（クリック＝押して離す なので体感同じ）


func _drop() -> void:
	if game_over or not can_drop or current_fruit == null:
		return
	current_fruit.freeze = false
	current_fruit = null
	can_drop = false
	await get_tree().create_timer(COOLDOWN).timeout
	can_drop = true
	_spawn_next()


func _spawn_next() -> void:
	if game_over:
		return
	var rank := next_rank
	next_rank = randi() % (SPAWN_MAX_RANK + 1)
	next_preview.show_rank(next_rank)
	var f := _make_fruit(rank)
	f.freeze = true
	var r: float = Fruit.RADII[rank]
	var start_x := clampf(aim_x, BIN_LEFT + r, BIN_RIGHT - r)
	f.position = Vector2(start_x, DROP_Y)
	add_child(f)
	current_fruit = f


# 果物を1個作って、合体シグナルを受け取れるようにして返す（まだツリーには入れない）
func _make_fruit(rank: int) -> Fruit:
	var f: Fruit = FRUIT.instantiate()
	f.rank = rank
	f.merge.connect(_on_merge)
	return f


func _on_merge(a: Fruit, b: Fruit) -> void:
	# このシグナルは物理計算の途中で飛んでくる。
	# その最中にノードを消したり足したりすると怒られるので、次フレームに回す
	_resolve_merge.call_deferred(a, b)


func _resolve_merge(a: Fruit, b: Fruit) -> void:
	if not is_instance_valid(a) or not is_instance_valid(b):
		return
	var new_rank: int = a.rank + 1
	var pos: Vector2 = (a.global_position + b.global_position) * 0.5

	# コンボ判定：前の合体から COMBO_WINDOW 秒以内なら継続
	var now := Time.get_ticks_msec() / 1000.0
	combo = combo + 1 if now - last_merge_sec <= COMBO_WINDOW else 1
	last_merge_sec = now

	var gained := (new_rank + 1) * 10 * combo
	score += gained
	_update_score()
	if combo >= 2:
		_popup_text(pos, "COMBO x%d!" % combo)

	a.queue_free()
	b.queue_free()

	# 一定確率で、できた玉を盤面に出さずアイテムとしてキープする（何個でもたまる）
	if randf() < ITEM_DROP_CHANCE:
		stock_queue.append(new_rank)
		_update_stock_ui()
		_popup_text(pos, "ITEM GET!")
		_play_sfx(SFX_POP, 1.6)
		_add_shake(2.0 + new_rank * 1.3)
		return

	var f := _make_fruit(new_rank)
	add_child(f)
	f.global_position = pos
	f.pop_in()

	# 演出：パーティクル ＋ 効果音（ランクが上がるほど高い音）＋ 画面シェイク
	_spawn_pop_fx(pos, Fruit.COLORS[new_rank])
	_play_sfx(SFX_POP, 1.0 + new_rank * 0.05)
	_add_shake(2.0 + new_rank * 1.3)


# キープ枠をタップ：先頭の1個を消費して、今持ってる（落とす前の）玉と差し替える
func _on_stock_pressed() -> void:
	if stock_queue.is_empty() or current_fruit == null:
		return
	var used_rank: int = stock_queue.pop_front()
	current_fruit.set_rank(used_rank)
	var r := current_fruit.radius
	current_fruit.position.x = clampf(current_fruit.position.x, BIN_LEFT + r, BIN_RIGHT - r)
	_update_stock_ui()
	_popup_text(current_fruit.global_position, "ITEM USE!")


func _update_stock_ui() -> void:
	stock_button.set_queue(stock_queue)


# 合体位置から上へ流れて消えるテキスト（コンボ表示用）
func _popup_text(pos: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.position = pos - Vector2(70, 24)
	l.z_index = 50
	l.add_theme_font_size_override("font_size", 34)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.4))
	add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 72.0, 0.7)
	t.tween_property(l, "modulate:a", 0.0, 0.7)
	t.chain().tween_callback(l.queue_free)


# 合体位置に一瞬だけ弾ける粒を出す
func _spawn_pop_fx(pos: Vector2, color: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 230.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color
	add_child(p)
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


# 使い捨ての AudioStreamPlayer で1回鳴らす（重なってもOK）
func _play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


# 落ちて止まっている果物がラインを超えていないか毎フレーム確認
func _check_game_over(delta: float) -> void:
	var over_line := false
	for node in get_tree().get_nodes_in_group("fruits"):
		var f := node as Fruit
		if f == null or not is_instance_valid(f):
			continue
		if f == current_fruit or f.freeze:
			continue  # 手に持っている（まだ落としてない）果物は対象外
		if f.global_position.y - f.radius < LINE_Y:
			over_line = true
			break
	if over_line:
		danger_time += delta
		if danger_time >= GAME_OVER_DELAY:
			_do_game_over()
	else:
		danger_time = 0.0


func _do_game_over() -> void:
	game_over = true
	var new_record := score > high_score
	if new_record:
		high_score = score
		_save_high_score()
	final_score_label.text = "SCORE %d" % score
	go_best_label.text = ">>  NEW RECORD  <<" if new_record else "BEST %d" % high_score
	game_over_panel.visible = true
	_play_sfx(SFX_GAMEOVER)
	if current_fruit != null:
		current_fruit.queue_free()
		current_fruit = null
	danger_time = 0.0
	_update_danger_line()  # 危険ラインを通常色に戻す
	drop_guide.visible = false
	stock_button.visible = false


func _update_score() -> void:
	score_label.text = "SCORE %d" % score
	best_label.text = "BEST %d" % maxi(high_score, score)


func _load_high_score() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) == OK:
		high_score = int(cf.get_value("score", "best", 0))


func _save_high_score() -> void:
	var cf := ConfigFile.new()
	cf.set_value("score", "best", high_score)
	cf.save(SAVE_PATH)
