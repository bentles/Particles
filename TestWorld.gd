extends Spatial


# 1. define a particle brain
# 2. spawn in N particles with that brain and let them do their thing for a bit
# 3. measure fitness somehow
# 4. mutate brain and go back to 2

const NeuralNetwork = preload("Neural Network/Brain.gd")
const Organism = preload("res://Organism/Organism.tscn")

var test_time_elapsed = 0
const TEST_TIME = 8 # secs to prove yourselfs
var max_fitness = 0

var generation = 0
var organisms = []
const GEN_SIZE = 8
var current_organism
var current_organism_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(0, GEN_SIZE):
		organisms.push_front(Organism.instance())
		
	current_organism = organisms[0]
	add_child(current_organism)
	
	pass # Replace with function body.

func _physics_process(delta):
	test_time_elapsed += delta
		
	if test_time_elapsed >= TEST_TIME:
		test_time_elapsed = 0
		max_fitness = max(current_organism.fitness, max_fitness)
		remove_child(current_organism)
		
		#on to the next one
		current_organism_index += 1
		
		if (current_organism_index < GEN_SIZE):
			current_organism = organisms[current_organism_index]
		else: 
			current_organism_index = 0
			create_next_generation()
			current_organism = organisms[current_organism_index]
			pass
			
		add_child(current_organism)
			
		
		
	
	var text = "fitness: " + str(current_organism.fitness)
	text += "\nmax_fitness: " + str(max_fitness)
	text += "\ntime: " + str(test_time_elapsed)
	text += "\n#: " + str(current_organism_index) + " of " + str(GEN_SIZE)
	text += "\ngen: " + str(generation)
	$MarginContainer/RichTextLabel.text = text

func roulette_select():
	var i = 0
	var r = randf()
	
	while r > 0:
		r = r - organisms[i].relative_fitness
		i += 1
	i -= 1
	
	return organisms[i]

func calculate_fitness():
	var sum = 0
	for org in organisms:
		sum += org.fitness
	
	for org in organisms:
		org.relative_fitness = org.fitness / sum

func create_next_generation():
	var next_gen = []
	calculate_fitness()
	for i in range(GEN_SIZE):
		var org = roulette_select()
		var brain = org.brain.duplicate()
		brain.mutate()
		var new_org = Organism.instance()
		new_org.brain = brain
		next_gen.push_front(new_org)
	
	for org in organisms:
		org.queue_free()
	
	generation += 1
	organisms = next_gen
