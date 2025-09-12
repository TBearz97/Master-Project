extends SpinBox  # this SpinBox is your "points pool"

@export var sbs : Array[SpinBox]
@export var maxValue : int

var _prev := {}  # SpinBox -> last value

func _ready() -> void:
	for sb in sbs:
		_prev[sb] = sb.value
		sb.value_changed.connect(_on_change.bind(sb))

func _on_change(new_value: float, sb: SpinBox) -> void:
	var last: float = _prev.get(sb, new_value)
	if new_value > last:
		self.value -= 1   # spend from pool
	elif new_value < last:
		self.value += 1   # refund to pool
	_prev[sb] = new_value

	# lock/unlock when pool hits zero / leaves zero
	if self.value == 0:
		for x in sbs:
			x.max_value = x.value
	else:
		for x in sbs:
			x.max_value = maxValue
