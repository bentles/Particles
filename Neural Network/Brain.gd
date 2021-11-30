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
