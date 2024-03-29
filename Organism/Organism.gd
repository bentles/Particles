extends Spatial

const NeuralNetwork = preload("res://Neural Network/Brain.gd")
const Particle = preload("res://Particle/Particle.tscn")

var particles = []
var brain: NeuralNetwork
var spawn_brain: NeuralNetwork
var target: Spatial
var material: Material
var particle_layer_offset = 0

var total_fitness = 0
var relative_fitness = 0
var fitness = 1
var age = 0

func _init():
	material = SpatialMaterial.new()
	material.set_local_to_scene(true)
	
	if brain == null:
		brain = NeuralNetwork.new(2, 8, 5)
	if spawn_brain == null:
		spawn_brain = NeuralNetwork.new(6, 6, 4)
		

# Called when the node enters the scene tree for the first time.
func _ready():
	_create_particles()
	pass # Replace with function body.
	
func _physics_process(delta):
		calc_fitness()
		
func record_fitness():
	total_fitness += fitness

func calc_fitness():
	# move far
	fitness = 0
	for p in particles:
		# fitness += p.global_transform.origin.y
		if (!p.global_transform.origin.distance_to(target.global_transform.origin) > 20):
			fitness += 20 / (p.global_transform.origin.distance_to(target.global_transform.origin))
		
	fitness /= particles.size()
	
	# bonuses
	#fitness += particles.size() * 10 # use particles
	#fitness += age * 10 # live longer 
	
	if is_nan(fitness):
		pass

func set_particle_layer_offset(i):
	particle_layer_offset = i

func _create_particles():
	particles = []
	for x in range(-1, 0):
		for y in range(2, 3):
			for z in range(-1, 2):
				spawn_particle(x, y, z)

func respawn():
	for p in particles:
		p.queue_free()
	_create_particles()

func spawn_at_child(particle, x, y , z, gen):
	var pos = particle.global_transform.origin
	
	spawn_particle(pos.x + x,
	 pos.y + y,
	 pos.z + z, 
	 gen)
	
func set_target(t: Spatial):
	target = t

func spawn_particle(x, y, z, gen = 1):
	var p = Particle.instance().duplicate()
	p.set_target(target)
	p.set_collision_layer(particle_layer_offset + 2)
	p.brain = brain.duplicate()
	p.spawn_brain = spawn_brain.duplicate()
	p.parent = self
	p.global_transform.origin = (Vector3(x, y, z))
	p.gen = gen
	particles.push_front(p)
	add_child(p)

func queue_free():
	for p in particles:
		p.queue_free()
		


