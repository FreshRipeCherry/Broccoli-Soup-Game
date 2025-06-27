extends StaticBody2D

@onready var collision: Area2D = $CollisionPoint

func _on_collision_point_area_entered(area: Area2D) -> void:
	if area.name != "GndPndHitbox":
		pass
	else:
		# debug print
		print("Block pounded")
		queue_free()
