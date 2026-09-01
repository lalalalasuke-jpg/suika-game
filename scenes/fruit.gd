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
## 見た目だけの拡大率（当たり判定には影響しない）。合体演出で一瞬大きくする
var draw_scale := 1.0


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


# 生成済みの果物のランクを後から変える（キープアイテムでの入れ替え用）
func set_rank(new_rank: int) -> void:
	rank = new_rank
	_apply_rank()


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


# 合体で生まれた果物を「ポンッ」と膨らませる演出
func pop_in() -> void:
	draw_scale = 0.25
	queue_redraw()
	var t := create_tween()
	t.tween_method(_set_draw_scale, 0.25, 1.0, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_draw_scale(v: float) -> void:
	draw_scale = v
	queue_redraw()


func _draw() -> void:
	# 演出中の拡大（以降の draw_* すべてに掛かる）
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(draw_scale, draw_scale))
	paint_face(self, radius, rank)


# 画像を使わず、顔つきの果物を任意の CanvasItem に描く。
# 本体（Fruit）とプレビュー（PreviewIcon）で共用する static 関数
static func paint_face(ci: CanvasItem, r: float, fruit_rank: int) -> void:
	var body: Color = COLORS[fruit_rank]
	var dark := Color(0.16, 0.12, 0.12)

	# 本体 ＋ 少し濃い輪郭 ＋ 左上のツヤ
	ci.draw_circle(Vector2.ZERO, r, body)
	ci.draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, body.darkened(0.35), maxf(2.0, r * 0.06), true)
	ci.draw_circle(Vector2(-r * 0.32, -r * 0.34), r * 0.30, Color(1, 1, 1, 0.22))

	# 目
	var eye_dx := r * 0.34
	var eye_y := -r * 0.06
	var eye_r := maxf(1.5, r * 0.11)
	if fruit_rank >= 9:
		# 大物は満足げな閉じ目 ^ ^
		var w := maxf(1.5, r * 0.05)
		ci.draw_arc(Vector2(-eye_dx, eye_y), r * 0.16, PI * 1.15, PI * 1.85, 12, dark, w, true)
		ci.draw_arc(Vector2(eye_dx, eye_y), r * 0.16, PI * 1.15, PI * 1.85, 12, dark, w, true)
	else:
		ci.draw_circle(Vector2(-eye_dx, eye_y), eye_r, dark)
		ci.draw_circle(Vector2(eye_dx, eye_y), eye_r, dark)
		ci.draw_circle(Vector2(-eye_dx + eye_r * 0.35, eye_y - eye_r * 0.35), eye_r * 0.4, Color(1, 1, 1, 0.85))
		ci.draw_circle(Vector2(eye_dx + eye_r * 0.35, eye_y - eye_r * 0.35), eye_r * 0.4, Color(1, 1, 1, 0.85))

	# 口（にっこり）
	ci.draw_arc(Vector2(0, r * 0.10), r * 0.30, PI * 0.15, PI * 0.85, 20, dark, maxf(1.5, r * 0.07), true)

	# ほっぺ（中ランク以上）
	if fruit_rank >= 4:
		ci.draw_circle(Vector2(-r * 0.52, r * 0.16), r * 0.14, Color(1, 0.5, 0.5, 0.30))
		ci.draw_circle(Vector2(r * 0.52, r * 0.16), r * 0.14, Color(1, 0.5, 0.5, 0.30))
