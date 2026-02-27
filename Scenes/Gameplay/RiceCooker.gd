# rice_cooker.gd
extends Sprite2D

@export_enum("White", "Brown") var rice_type: String = "White"

@export_group("White Rice Textures")
@export var wr_closed_texture: Texture2D
@export var wr_open_texture: Texture2D

@export_group("Brown Rice Textures")
@export var br_closed_texture: Texture2D
@export var br_open_texture: Texture2D

# Scale settings
@export_group("Transform Settings")
@export var closed_scale: Vector2 = Vector2(1, 1)
@export var open_scale: Vector2 = Vector2(0.8, 0.8) 
@export var closed_offset: Vector2 = Vector2(0, 0)
@export var open_offset: Vector2 = Vector2(0, -100) 

# Active textures cache
var active_closed: Texture2D
var active_open: Texture2D

func _ready():
	if rice_type == "White":
		active_closed = wr_closed_texture
		active_open = wr_open_texture
	else:
		active_closed = br_closed_texture
		active_open = br_open_texture
		
	texture = active_closed
	scale = closed_scale
	offset = closed_offset

func open_cooker():
	texture = active_open
	scale = open_scale
	offset = open_offset

func close_cooker():
	texture = active_closed
	scale = closed_scale
	offset = closed_offset
