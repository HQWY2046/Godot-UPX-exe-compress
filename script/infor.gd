extends TextureRect
@export_multiline var text:String
@onready var label: Label = $Label

func _ready() -> void:
	label.visible = false
	label.text = text
	

func _on_mouse_entered() -> void:
	label.visible = true


func _on_mouse_exited() -> void:
	label.visible = false
