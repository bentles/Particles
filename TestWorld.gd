extends Spatial

# 1. define a particle brain
# 2. spawn in N particles with that brain and let them do their thing for a bit
# 3. measure fitness somehow
# 4. mutate brain and go back to 2

const NeuralNetwork = preload("Neural Network/Brain.gd")
const Organism = preload("res://Organism/Organism.tscn")

var test_time_elapsed = 0
const TEST_TIME = 8 # secs to prove yourself
var max_fitness = 0
var max_fitness_brain
var ave_fitness = 0
var tourn_perc = 0.5
var parallel_organisms = 1

var generation = 0
var organisms = []
const GEN_SIZE = 48
var current_organisms = []
var current_organism_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	assert(parallel_organisms < 11)
	assert(GEN_SIZE % parallel_organisms == 0)
	
	for i in range(GEN_SIZE):
		organisms.push_front(Organism.instance().duplicate())
		
	current_organisms = _get_current_organisms(0, parallel_organisms, organisms)	
	_add_current_organisms()
	
	randomize()
	
	pass # Replace with function body.
	
func _add_current_organisms():
	for i in range(current_organisms.size()):
		current_organisms[i].particle_layer_offset = i
		add_child(current_organisms[i])
	
func _get_current_organisms(start, count, all):
	var org = []
	for i in range(start, start + count):
		org.push_back(all[i])
	return org

func _physics_process(delta):
	test_time_elapsed += delta
		
	if test_time_elapsed >= TEST_TIME:
		test_time_elapsed = 0
		
		for current_organism in current_organisms:
			if current_organism.fitness > max_fitness:
				max_fitness = current_organism.fitness
				max_fitness_brain = current_organism.brain.duplicate()
			remove_child(current_organism)
		
		#on to the next one
		current_organism_index += parallel_organisms
		
		if (current_organism_index < GEN_SIZE):
			current_organisms = _get_current_organisms(current_organism_index, parallel_organisms, organisms)
		else: 
			current_organism_index = 0
			create_next_generation()
			current_organisms = _get_current_organisms(current_organism_index, parallel_organisms, organisms)
			pass
		
		_add_current_organisms()

	
func _process(delta):
	var text = ""
	for org in current_organisms:
		text += "\nfitness: " + str(org.fitness)
	text += "\nmax_fitness: " + str(max_fitness)
	text += "\nave_fitness: " + str(ave_fitness)
	text += "\ntime: " + str(test_time_elapsed)
	text += "\n#: " + str(current_organism_index + 1) + " of " + str(GEN_SIZE)
	text += "\ngen: " + str(generation)
	text += "\nfps: " + str(Engine.get_frames_per_second())
	$MarginContainer/RichTextLabel.text = text


func tourn_select():
	var tourn_size = GEN_SIZE * tourn_perc
	var best_fitness = 0
	var best_organism
	for i in range(0, tourn_size):
		var rand_selection = randi() % GEN_SIZE
		if organisms[rand_selection].fitness > best_fitness:
			best_fitness = organisms[rand_selection].fitness
			best_organism = organisms[rand_selection]
	return best_organism

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
		
	ave_fitness = sum / GEN_SIZE
	
	for org in organisms:
		org.relative_fitness = org.fitness / sum

func create_next_generation():
	var next_gen = []
	calculate_fitness()
	while next_gen.size() < GEN_SIZE:
		var b1 = tourn_select().brain.duplicate()
		var b2 = tourn_select().brain.duplicate()
		b1.crossover_mutate(b2)
		var new1 = Organism.instance().duplicate()
		var new2 = Organism.instance().duplicate()
		new1.brain = b1
		new2.brain = b2
		
		next_gen.push_back(new1)
		next_gen.push_back(new2)
	
	for org in organisms:
		org.queue_free()
	
	generation += 1
	organisms = next_gen

