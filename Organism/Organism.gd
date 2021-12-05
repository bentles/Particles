extends Spatial

const NeuralNetwork = preload("res://Neural Network/Brain.gd")
const Particle = preload("res://Particle/Particle.tscn")
var particles = []
var brain: NeuralNetwork
var particle_layer_offset = 0
var relative_fitness = 0
var fitness = 0

func _init():
	if brain == null:
		brain = NeuralNetwork.new(7, 12, 2)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	_create_particles()
	pass # Replace with function body.
	
func _physics_process(_delta):
	calc_fitness()

func calc_fitness():
	fitness = 0
	for p in particles:
		fitness +=  transform.origin.distance_squared_to(p.global_transform.origin)
	if is_nan(fitness):
		pass


func _create_particles():
	particles = []
	for x in range(-1, 1):
		for y in range(4, 6):
			for z in range(-1, 1):
				var p = Particle.instance().duplicate()
				p.set_collision_layer(particle_layer_offset + 2)
				p.brain = brain # might need some kind of instancing thing here
				p.translate(Vector3(x, y, z))
				particles.push_front(p)
				add_child(p)
				
func queue_free():
	for p in particles:
		p.queue_free()

