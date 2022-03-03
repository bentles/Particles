extends Spatial

const NeuralNetwork = preload("res://Neural Network/Brain.gd")
const Particle = preload("res://Particle/Particle.tscn")

var particles = []
export var hp: float = 40
var brain: NeuralNetwork
var spawn_brain: NeuralNetwork
var target: Spatial
var material: Material
var particle_layer_offset = 0

var relative_fitness = 0
var fitness = 1
var age = 0

func _init():
	material = SpatialMaterial.new()
	material.set_local_to_scene(true)
	var texture = ImageTexture.new()
	var image = Image.new()
	image.load("res://Particle/6056-normal.jpg")
	texture.create_from_image(image)

	material.albedo_texture = texture
	
	if brain == null:
		brain = NeuralNetwork.new(10, 20, 2)
	if spawn_brain == null:
		spawn_brain = NeuralNetwork.new(7, 6, 4)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	_create_particles()
	pass # Replace with function body.
	
func _physics_process(delta):
	if hp <= 0:
		for p in particles:
			p.kill()
	else:
		age += delta
		calc_fitness()

func calc_fitness():
	# move far
	fitness = 0
	for p in particles:
		# fitness += p.global_transform.origin.y
		fitness += 1 / p.global_transform.origin.distance_squared_to(target.global_transform.origin)
		
	fitness /= particles.size()
	
	# bonuses
	#fitness += particles.size() * 10 # use particles
	#fitness += age * 10 # live longer 
	
	if is_nan(fitness):
		pass

func set_particle_layer_offset(i):
	particle_layer_offset = i
	var colors = [Color.cadetblue, Color.webpurple, Color.tomato, Color.crimson, Color.darkred, Color.darkgreen]
	var color: Color = colors[particle_layer_offset % colors.size()]
	# material.albedo_color = color

func _create_particles():
	particles = []
	for x in range(-1, 1):
		for y in range(2, 4):
			for z in range(-1, 1):
				spawn_particle(x, y, z)
				
func spawn_at_child(particle, x, y , z, gen):
	var pos = particle.transform.origin
	
	spawn_particle(pos.x + x,
	 pos.y + y,
	 pos.z + z, 
	 gen)
	
func set_target(t: Spatial):
	target = t

func spawn_particle(x, y, z, gen = 1):
	var p = Particle.instance().duplicate()
	p.set_target(target)
	p.set_material(material)
	p.set_collision_layer(particle_layer_offset + 2)
	p.brain = brain # might need some kind of instancing thing here
	p.spawn_brain = spawn_brain
	p.parent = self
	p.translate(Vector3(x, y, z))
	p.gen = gen
	particles.push_front(p)
	add_child(p)
	hp -= 1

func queue_free():
	for p in particles:
		p.queue_free()

