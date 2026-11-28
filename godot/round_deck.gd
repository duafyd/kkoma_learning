extends RefCounted

const CATALOG := preload("res://activity_catalog.json")
const TOPICS := {"hangul":"K", "english":"E", "numbers":"M"}
const AREAS := ["K", "E", "M", "O", "P"]

static func generate(route: String, age: int, writing: bool, seen: Array, last: Array, practice: Array) -> Array:
	var result: Array = []
	if route in ["shop", "bakery"]:
		var prefix := ("F" if route == "shop" else "B") + str(age) + "-"
		var practiced_writing := false
		var area_order := AREAS.duplicate()
		# Set a different writing opportunity on each mixed round.
		area_order.shuffle()
		for area in area_order:
			var pool := [prefix + area + "1", prefix + area + "2"]
			if practiced_writing and CATALOG.data[pool[1]].task == "trace":
				pool.pop_back()
			var key := choose(pool, seen, practice)
			result.append(key)
			practiced_writing = practiced_writing or CATALOG.data[key].task == "trace"
	else:
		var topic: String = TOPICS[route]
		var prefix := "W" + str(age) + "-" + topic
		var strokes := [prefix + "1", prefix + "2", prefix + "3"]
		if writing:
			result = strokes
		else:
			var fruit := "F" + str(age) + "-" + topic
			var bread := "B" + str(age) + "-" + topic
			var independent := "S" + str(age) + "-" + topic
			var extra := [bread + "1", fruit + "2", bread + "2"].filter(func(k): return CATALOG.data[k].task != "trace")
			if CATALOG.data.has(independent + "1"):
				if topic == "M":
					result = [choose([independent + "1", independent + "2"], seen, practice), choose([fruit + "1", bread + "1"], seen, practice), choose(strokes, seen, practice)]
				else:
					result = [choose([fruit + "1", bread + "1"], seen, practice), choose([independent + "1", independent + "2"], seen, practice), choose(strokes, seen, practice)]
			else:
				result = [fruit + "1", choose(extra, seen, practice), choose(strokes, seen, practice)]
	result.shuffle()
	var is_shop := route in ["shop", "bakery"]
	var used: Array = []
	var ordered: Array = []
	while not result.is_empty():
		var index := 0
		for i in result.size():
			var candidate: String = result[i]
			if ordered.is_empty() and not last.is_empty() and (identity(candidate) == identity(last[0]) if is_shop else candidate == last[0]):
				continue
			var task: String = CATALOG.data[candidate].task
			if not used.is_empty() and gesture(task) == used.back():
				continue
			index = i
			break
		var key: String = result.pop_at(index)
		ordered.append(key)
		used.append(gesture(CATALOG.data[key].task))
	return ordered

static func gesture(task: String) -> String:
	return task if task in ["fill", "trace", "layout", "repair", "dots"] else "select"

static func choose(keys: Array, seen: Array, practice: Array) -> String:
	var next: String = keys[0]
	var score := -99999
	for key in keys:
		var position := seen.rfind(key)
		var points := -position
		if position < 0:
			points += seen.size() + 2
		# A different example of a recent assisted goal gets first chance.
		for other in practice:
			if other != key and other is String and other.length() == 5 and other[3] == key[3]:
				points += 2
				break
		if points > score:
			score = points
			next = key
	return next

static func identity(key: String) -> String:
	return key[3] if CATALOG.data.has(key) else key
