extends Area2D

@export var value: int = 1 

var velocidad_y = 0.0
var gravedad = 900.0
var en_el_suelo = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	
func _on_body_entered(body: Node) -> void:
	#print("Body")
	if body.is_in_group("Player"):
		Global.add_potions(value)
		$PowerUp.play()
		$Sprite2D.visible = false
		$CollisionShape2D.queue_free() 
		await get_tree().create_timer(2.5).timeout
		queue_free()
	#if body.is_in_group("Ground"):
		#print("body piso")
		#en_el_suelo = true
		#velocidad_y = 0
		#$PowerUp.play()
	# Si el objeto que tocamos es el suelo (un StaticBody2D)
	
		
		
		
func _process(delta):
	if not en_el_suelo:
		# Aplicar gravedad
		velocidad_y += gravedad * delta
		position.y += velocidad_y * delta
		
func _physics_process(delta: float) -> void:
	if en_el_suelo:
		velocidad_y = 0

func _on_area_entered(area: Area2D) -> void:
	#print("Area")
	if area.is_in_group("Ground"):
		print("area piso")
		print(position.y)
		en_el_suelo = true
		velocidad_y = 0
		# Ajustar posición para que no se hunda (opcional)
	pass # Replace with function body.


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
