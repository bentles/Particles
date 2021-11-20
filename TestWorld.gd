extends Spatial


# 1. define a particle brain
# 2. spawn in N particles with that brain and let them do their thing for a bit
# 3. measure fitness somehow
# 4. mutate brain and go back to 2

const NeuralNetwork = preload("Neural Network/Brain.gd")
const Particle = preload("res://Particle/Particle.tscn")

var test_time_elapsed = 0
var test_time = 5 # 5 secs to prove yourself
var particles = []

# Called when the node enters the scene tree for the first time.
func _ready():
	var brain = NeuralNetwork.new(3, 5, 3)
	
	for x in range(-1, 2):
		for y in range(1, 3):
			for z in range(-1, 2):
				var p = Particle.instance()
				p.brain = brain #might need some kind of instancing thing here
				p.translate(Vector3(x, y, z))
				particles.push_front(p)
				add_child(p)
				
	
	pass # Replace with function body.


func _physics_process(delta):
	test_time_elapsed = move_toward(test_time_elapsed, test_time, delta)
	
	# TODO: save max fitness and mutate here after test_time has passed
	
	var fitness = 0
	
	for p in particles:
		fitness += abs(p.global_transform.origin.x)
		fitness += abs(p.global_transform.origin.z)
		
	$MarginContainer/RichTextLabel.text = "fitness: " + str(fitness)
	pass
