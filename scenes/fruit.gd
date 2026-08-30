class_name Fruit
extends RigidBody2D

# 「この果物と、相手の果物が合体すべき」と main に伝える合図
signal merge(a: Fruit, b: Fruit)

# ランクごとの半径（ピクセル）。index がそのまま rank
const RADII := [26.0, 34.0, 44.0, 56.0, 70.0, 84.0, 100.0, 118.0, 138.0, 160.0, 185.0]
# ランクごとの色（画像を入れるまでの仮ビジュアル）
const COLORS: Array[Color] = [
	Color("e74c3c"), Color("e67e22"), Color("9b59b6"), Color("f1c40f"),
	Color("e84393"), Color("c0392b"), Color("16a085"), Color("2980b9"),
	Color("27ae60"), Color("d35400"), Color("2ecc71"),
]
# 一番上のランク（これ以上は合体しない）
const MAX_RANK := 10

## この果物のランク。add_child する前に main がセットする
var rank := 0
## rank から決まる半径。_apply_rank でセット
var radius := RADII[0]
## 合体で消費済みフラグ。二重合体を防ぐ
var merged := false


func _ready() -> void:
	_apply_rank()
	# 「fruits」グループに登録。main がまとめて見つけられるようにする
	add_to_group("fruits")
	# 他の物体に触れたら _on_body_entered が呼ばれるようにする
	body_entered.connect(_on_body_entered)


# rank に合わせて当たり判定の円と見た目を更新
func _apply_rank() -> void:
	radius = RADII[rank]
	var circle := CircleShape2D.new()
	circle.radius = radius
	$CollisionShape2D.shape = circle
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	# すでに消費済み or 最大ランクなら何もしない
	if merged or rank >= MAX_RANK:
		return
	# 相手が果物じゃない（＝壁や床）なら無視
	if not (body is Fruit):
		return
	var other := body as Fruit
	# ランクが違う or 相手が消費済みなら合体しない
	if other.merged or other.rank != rank:
		return
	# A↔B がぶつかると通知は両方に飛ぶ。ID が小さい方だけが処理して1回に絞る
	if get_instance_id() > other.get_instance_id():
		return
	merged = true
	other.merged = true
	merge.emit(self, other)


# 画像を使わず、rank の色の丸に顔を描いて「絵文字キャラ」っぽくする
func _draw() -> void:
	var body: Color = COLORS[rank]
	var dark := Color(0.16, 0.12, 0.12)

	# 本体 ＋ 少し濃い輪郭
	draw_circle(Vector2.ZERO, radius, body)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, body.darkened(0.35), maxf(2.0, radius * 0.06), true)
	# 左上のツヤ
	draw_circle(Vector2(-radius * 0.32, -radius * 0.34), radius * 0.30, Color(1, 1, 1, 0.22))

	# 目
	var eye_dx := radius * 0.34
	var eye_y := -radius * 0.06
	var eye_r := maxf(1.5, radius * 0.11)
	if rank >= 9:
		# 大物は満足げな閉じ目 ^ ^
		var w := maxf(1.5, radius * 0.05)
		draw_arc(Vector2(-eye_dx, eye_y), radius * 0.16, PI * 1.15, PI * 1.85, 12, dark, w, true)
		draw_arc(Vector2(eye_dx, eye_y), radius * 0.16, PI * 1.15, PI * 1.85, 12, dark, w, true)
	else:
		draw_circle(Vector2(-eye_dx, eye_y), eye_r, dark)
		draw_circle(Vector2(eye_dx, eye_y), eye_r, dark)
		draw_circle(Vector2(-eye_dx + eye_r * 0.35, eye_y - eye_r * 0.35), eye_r * 0.4, Color(1, 1, 1, 0.85))
		draw_circle(Vector2(eye_dx + eye_r * 0.35, eye_y - eye_r * 0.35), eye_r * 0.4, Color(1, 1, 1, 0.85))

	# 口（にっこり）
	draw_arc(Vector2(0, radius * 0.10), radius * 0.30, PI * 0.15, PI * 0.85, 20, dark, maxf(1.5, radius * 0.07), true)

	# ほっぺ（中ランク以上）
	if rank >= 4:
		draw_circle(Vector2(-radius * 0.52, radius * 0.16), radius * 0.14, Color(1, 0.5, 0.5, 0.30))
		draw_circle(Vector2(radius * 0.52, radius * 0.16), radius * 0.14, Color(1, 0.5, 0.5, 0.30))
