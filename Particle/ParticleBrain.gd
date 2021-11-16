const NeuralNetwork = preload("../Neural Network/Brain.gd")


var neural_network = NeuralNetwork.new(2,5,3)

# ok i think each particle should know about the particles next to it
# so maybe direction vectors to the particles in its sphere??
# definitely should know the state of the particles next to it

# 3 outputs: expand, contract, do nothing
# inputs: what particles around it are doing
# how on earth do I format this??

# some number of middle nodes

# states:
# 0: rest, 1: expanding, 2: expanded, 3:contracting

# rest and expanded states need cooldowns.
	
# fitness will be measured by distance from start point

# want to lose as few particles as possible. so being alone is not gucci
# maybe not being alone will be an emergent property of movement if
# having more particles will allow it to move faster??
# will try exclude that condition at first

# neural_network.predict(inputs: Array)
# neural_network.duplicate()
# neural_network.mutation_rate = mutation_rate
# neural_network.mutate()

