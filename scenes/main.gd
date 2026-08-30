extends Node2D

const FRUIT := preload("res://scenes/fruit.tscn")

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

var current_fruit: Fruit = null
var can_drop := true
var score := 0
var game_over := false
# 果物がラインを超えている状態が続いている時間
var danger_time := 0.0

@onready var score_label: Label = $HUD/ScoreLabel
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var final_score_label: Label = $HUD/GameOverPanel/FinalScore


func _ready() -> void:
	_update_score()
	_spawn_next()


func _process(delta: float) -> void:
	if game_over:
		return
	if current_fruit != null:
		var r := current_fruit.radius
		current_fruit.position.x = clampf(get_global_mouse_position().x, BIN_LEFT + r, BIN_RIGHT - r)
	_check_game_over(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if game_over:
			get_tree().reload_current_scene()  # シーンを丸ごと読み直して最初から
		else:
			_drop()


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
	var rank := randi() % (SPAWN_MAX_RANK + 1)
	var f := _make_fruit(rank)
	f.freeze = true
	var r: float = Fruit.RADII[rank]
	var start_x := clampf(get_global_mouse_position().x, BIN_LEFT + r, BIN_RIGHT - r)
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

	score += (new_rank + 1) * 10
	_update_score()

	a.queue_free()
	b.queue_free()

	var f := _make_fruit(new_rank)
	add_child(f)
	f.global_position = pos


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
	final_score_label.text = "スコア: %d" % score
	game_over_panel.visible = true
	if current_fruit != null:
		current_fruit.queue_free()
		current_fruit = null


func _update_score() -> void:
	score_label.text = "スコア: %d" % score
