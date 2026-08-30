class_name PreviewIcon
extends Node2D

# 「次の果物」を HUD に小さく表示するだけのノード。物理も衝突も無い。
var rank := 0


func show_rank(r: int) -> void:
	rank = r
	queue_redraw()


func _draw() -> void:
	# 実サイズだと大きすぎるので上限 38px で表示
	Fruit.paint_face(self, minf(Fruit.RADII[rank], 38.0), rank)
