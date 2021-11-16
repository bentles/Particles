extends RigidBody

# Declare member variables here. Examples:
var vel3 = Vector3.ZERO
var neg_z3 = Vector3(0,0,-2)
var pos_z3 = Vector3(0,0,2)
export var fmass = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# assume for now all particles are the same mass so i just pick a
	# value for G*m1*m2
	var gmm = 5.0
	
	var overlapping_neg_z = $InfluenceAreaNegZ.get_overlapping_bodies()
	var overlapping_pos_z = $InfluenceAreaPosZ.get_overlapping_bodies()
	
	for body in overlapping_neg_z:
		if body != self: #not myself lol
			var end = ($InfluenceAreaNegZ.global_transform.origin)
			var rsq = end.distance_squared_to(body.global_transform.origin)
			var r3 = end.direction_to(body.global_transform.origin)
			var acc3 = r3 * ((gmm * body.fmass * self.fmass)/(rsq))
			self.add_force(acc3, body.global_transform.origin - $InfluenceAreaNegZ.global_transform.origin)
			
	for body in overlapping_pos_z:
		if body != self: #not myself lol
			var end = ($InfluenceAreaPosZ.global_transform.origin)
			var rsq = end.distance_squared_to(body.global_transform.origin)
			var r3 = end.direction_to(body.global_transform.origin)
			var acc3 = r3 * ((gmm * body.fmass * self.fmass)/(rsq))
			self.add_force(acc3, body.global_transform.origin - $InfluenceAreaPosZ.global_transform.origin)
	
	pass
	
func get_offsets():
	return [$InfluenceAreaNegZ/CollisionShape.global_transform.origin,
	 $InfluenceAreaPosZ/CollisionShape.global_transform.origin]
