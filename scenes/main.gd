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

var current_fruit: Fruit = null
var can_drop := true
var score := 0

@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	_update_score()
	_spawn_next()


func _process(_delta: float) -> void:
	if current_fruit != null:
		var r := current_fruit.radius
		current_fruit.position.x = clampf(get_global_mouse_position().x, BIN_LEFT + r, BIN_RIGHT - r)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_drop()


func _drop() -> void:
	if not can_drop or current_fruit == null:
		return
	current_fruit.freeze = false
	current_fruit = null
	can_drop = false
	await get_tree().create_timer(COOLDOWN).timeout
	can_drop = true
	_spawn_next()


func _spawn_next() -> void:
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


func _update_score() -> void:
	score_label.text = "スコア: %d" % score
