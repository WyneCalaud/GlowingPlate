extends Sprite2D # or StaticBody2D/Area2D depending on your setup

@export var closed_texture: Texture2D
@export var open_texture: Texture2D

@export var open_scale: Vector2 = Vector2(0.27, 0.27) 
@export var closed_scale: Vector2 = Vector2(0.2, 0.2) 

@export var open_offset: Vector2 = Vector2(0, -325)
@export var closed_offset: Vector2 = Vector2(0, -50)

func _ready():
	texture = closed_texture
	scale = closed_scale
	offset = closed_offset

func open_cooker():
	texture = open_texture
	scale = open_scale
	offset = open_offset

func close_cooker():
	texture = closed_texture
	scale = closed_scale
	offset = closed_offset
