extends CharacterBody2D

@export var value: int = 1 

var gravedad = 980 # Fuerza de atracción
var velocidad = Vector2.ZERO

var en_el_suelo = false
var recolectado = false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.area_entered.connect(_on_area_entered)

	pass
	
	
func _on_body_entered(body: Node) -> void:
	#print("Body")
	if body.is_in_group("Player"):
		recolectado = true
		Global.add_potions(value)
		$PowerUp.play()
		$Sprite2D.visible = false
		$CollisionShape2D.queue_free() 
		await get_tree().create_timer(2.5).timeout
		queue_free()
		
		
		
func _physics_process(delta):
	# Si NO está tocando el suelo, aplicamos gravedad
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		velocity.y = 0
		#print("en el piso")
		destruir()
		
	# Mueve el objeto y detecta colisiones automáticamente
	move_and_slide()

func destruir():
	await get_tree().create_timer(5).timeout
	if !recolectado:
		$Sprite2D.visible = false
		$Area2D.queue_free()
		$CollisionShape2D.queue_free()
		queue_free()
	pass
	
	
func _on_area_entered(area: Area2D) -> void:
	#print("Area")
	#if area.is_in_group("Ground"):
		#print("area piso")
		#print(position.y)
		#en_el_suelo = true
		#velocity.y = 0
		# Ajustar posición para que no se hunda (opcional)
	pass # Replace with function body.
