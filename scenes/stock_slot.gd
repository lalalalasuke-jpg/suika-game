class_name StockSlot
extends Button

## キープ中の果物のランクを、手に入れた順に並べたもの。先頭が次に使われる
var queue: Array[int] = []


func set_queue(q: Array[int]) -> void:
	queue = q
	visible = not queue.is_empty()
	queue_redraw()


func _draw() -> void:
	if queue.is_empty():
		return
	var center := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 6.0
	draw_set_transform(center, 0.0, Vector2.ONE)
	Fruit.paint_face(self, r, queue[0])
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 2個以上たまってたら右上に「x個数」バッジ
	if queue.size() > 1:
		var badge_pos := Vector2(size.x - 16, 16)
		draw_circle(badge_pos, 13.0, Color(0.9, 0.25, 0.25))
		var font := ThemeDB.fallback_font
		var font_size := 16
		var text := "x%d" % queue.size()
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_pos := badge_pos - text_size * 0.5 + Vector2(0, text_size.y * 0.35)
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1))
