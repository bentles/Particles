const Matrix = preload("Matrix.gd")
const MatrixOperator = preload("MatrixOperator.gd")

var input_nodes := 0
var hidden_nodes := 0
var output_nodes := 0
 
var weights_ih: Matrix # input -> hidden
var weights_ho: Matrix # hidden -> output
var bias_h: Matrix
var bias_o: Matrix

var learning_rate = 1
var mutation_rate = 0.1

var sigmoid_ref: FuncRef
var relu_ref: FuncRef
var dsigmoid_ref: FuncRef
var mutation_func_ref: FuncRef

var rng: RandomNumberGenerator

# CONSTRUCTORS
func _init(a, b = 1, c = 1):
	randomize()
	rng = RandomNumberGenerator.new()
	rng.randomize()
	sigmoid_ref = funcref(self, 'sigmoid')
	relu_ref = funcref(self, 'relu')
	dsigmoid_ref = funcref(self, "dsigmoid")
	mutation_func_ref = funcref(self, "mutation_func")
	
	if a is int:
		construct_from_sizes(a, b, c)
	else:
		construct_from_nn(a)

func construct_from_sizes(a, b, c):
	input_nodes = a
	hidden_nodes = b
	output_nodes = c
	
	weights_ih = Matrix.new(hidden_nodes, input_nodes)
	weights_ho = Matrix.new(output_nodes, hidden_nodes)
	weights_ih.randomize()
	weights_ho.randomize()
	
	bias_h = Matrix.new(hidden_nodes, 1)
	bias_o = Matrix.new(output_nodes, 1)
	bias_h.randomize()
	bias_o.randomize()

func construct_from_nn(a):
	input_nodes = a.input_nodes
	hidden_nodes = a.hidden_nodes
	output_nodes = a.output_nodes
	
	weights_ih = a.weights_ih.duplicate()
	weights_ho = a.weights_ho.duplicate()
	
	bias_h = a.bias_h.duplicate()
	bias_o = a.bias_o.duplicate()

func predict(input_array: Array) -> Array:
	var inputs = Matrix.new(input_array)
	
	var hidden = MatrixOperator.multiply(weights_ih, inputs)
	hidden.add(bias_h)
	hidden.map(relu_ref)
	
	var outputs = MatrixOperator.multiply(weights_ho, hidden)
	outputs.add(bias_o)
	outputs.map(sigmoid_ref)
	
	return outputs.to_array()
	

func mutate():
	weights_ih.map(mutation_func_ref)
	weights_ho.map(mutation_func_ref)
	bias_h.map(mutation_func_ref)
	bias_o.map(mutation_func_ref)
	
func crossover_mutate(brain):
	var ih1 = weights_ih.to_array()
	var ih2 = brain.weights_ih.to_array()
	var ho1 = weights_ho.to_array()
	var ho2 = brain.weights_ho.to_array()
	var h1 = bias_h.to_array()
	var h2 = brain.bias_h.to_array()
	var o1 = bias_o.to_array()
	var o2 = brain.bias_o.to_array()
	
	for i in range(ih1.size()):
		_swap(i, ih1, ih2)
	for i in range(ho1.size()):
		_swap(i, ho1, ho2)
	for i in range(h1.size()):
		_swap(i, h1, h2)
	for i in range(o1.size()):
		_swap(i, o1, o2)
		
	weights_ih.from_array(ih1)
	brain.weights_ih.from_array(ih2)
	weights_ho.from_array(ho1)
	brain.weights_ho.from_array(ho2)
	bias_h.from_array(h1)
	brain.bias_h.from_array(h2)
	bias_o.from_array(o1)
	brain.bias_o.from_array(o2)
	
	mutate()
	brain.mutate()
	
func _swap(i, a, b):
	if (randf() < 0):
			var tmp = a[i]
			a[i] = b[i]
			b[i] = tmp

func duplicate():
	return get_script().new(self)

func mutation_func(val):
	if randf() < mutation_rate:
		return val + rng.randfn(0, 0.2)
	else:
		return val

func sigmoid(x):
	return 1 / (1 + exp(-x))

# func softMax(x):
# 	e^x / sum(e^x)

func relu(x):
	return max(x, 0)

func dsigmoid(y):
	return y * (1 - y)
