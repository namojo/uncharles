class_name DialogueCondition
extends RefCounted
## A small, safe condition evaluator for dialogue data (no Expression, no code
## execution). Implements Story 002
## (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## Grammar:
##   or      := and ("or" and)*
##   and     := not ("and" not)*
##   not     := "not" not | compare
##   compare := operand (("==" | "!=" | ">=" | "<=" | ">" | "<") operand)?
##   operand := integer | name | "(" or ")"
## Names: `affinity.<candidate>`, `flag.<name>` (1 when set, else 0), a counter
## (`jobs_completed`, `reboot_count`, `money`, `battery`) or a threshold name
## from affinity_values.json. A bare operand is true when it is not 0.
## Every name is resolved when the condition is parsed, so a wrong name fails
## at load time instead of during play.

const KEYWORDS: PackedStringArray = ["and", "or", "not"]
const COMPARE_OPS: PackedStringArray = ["==", "!=", ">=", "<=", ">", "<"]

## Empty when the expression parsed; otherwise why it did not.
var error: String = ""
## Flag names the expression reads, so the data loader can check they exist.
var flags_read: PackedStringArray = PackedStringArray()

var _tokens: PackedStringArray = PackedStringArray()
var _pos: int = 0
var _vocab: Dictionary = {}
var _tree: Array = []


## Parses `expression`. `vocabulary` holds `candidates` (Array), `counters`
## (Dictionary keyed by name) and `thresholds` (name -> int). Check `error`.
static func parse(expression: String, vocabulary: Dictionary) -> DialogueCondition:
	var condition := DialogueCondition.new()
	condition._vocab = vocabulary
	condition._tokens = condition._tokenize(expression)
	if condition.error.is_empty():
		condition._tree = condition._parse_or()
		if condition.error.is_empty() and condition._pos < condition._tokens.size():
			condition.error = "unexpected '%s'" % condition._tokens[condition._pos]
	return condition


## True when the condition holds for `store`.
func evaluate(store: AffinityStore) -> bool:
	return _truthy(_eval(_tree, store))


func _tokenize(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var i: int = 0
	while i < text.length():
		var c: String = text[i]
		if c == " " or c == "\t":
			i += 1
		elif c == "(" or c == ")":
			out.append(c)
			i += 1
		elif c in ["=", "!", ">", "<"]:
			var two: String = text.substr(i, 2)
			if two in COMPARE_OPS:
				out.append(two)
				i += 2
			elif c in [">", "<"]:
				out.append(c)
				i += 1
			else:
				error = "unreadable '%s'" % text.substr(i)
				return out
		elif c.is_valid_int():
			var start: int = i
			while i < text.length() and text[i].is_valid_int():
				i += 1
			out.append(text.substr(start, i - start))
		elif c == "_" or (c.unicode_at(0) < 128 and c.to_lower() != c.to_upper()):
			var start: int = i
			while i < text.length() and (text[i] == "_" or text[i] == "." or text[i].is_valid_int() \
					or (text[i].unicode_at(0) < 128 and text[i].to_lower() != text[i].to_upper())):
				i += 1
			out.append(text.substr(start, i - start))
		else:
			error = "unreadable '%s'" % text.substr(i)
			return out
	return out


func _peek() -> String:
	return _tokens[_pos] if _pos < _tokens.size() else ""


func _parse_or() -> Array:
	var left: Array = _parse_and()
	while error.is_empty() and _peek() == "or":
		_pos += 1
		left = ["or", left, _parse_and()]
	return left


func _parse_and() -> Array:
	var left: Array = _parse_not()
	while error.is_empty() and _peek() == "and":
		_pos += 1
		left = ["and", left, _parse_not()]
	return left


func _parse_not() -> Array:
	if _peek() == "not":
		_pos += 1
		return ["not", _parse_not()]
	var left: Array = _parse_operand()
	if error.is_empty() and _peek() in COMPARE_OPS:
		var op: String = _peek()
		_pos += 1
		return ["cmp", op, left, _parse_operand()]
	return left


func _parse_operand() -> Array:
	var token: String = _peek()
	if token.is_empty():
		error = "expression ends too early"
		return []
	_pos += 1
	if token == "(":
		var inner: Array = _parse_or()
		if error.is_empty():
			if _peek() != ")":
				error = "missing ')'"
			else:
				_pos += 1
		return inner
	if token.is_valid_int():
		return ["num", token.to_int()]
	if token in KEYWORDS or token == ")" or token in COMPARE_OPS:
		error = "unexpected '%s'" % token
		return []
	return _name_operand(token)


func _name_operand(token: String) -> Array:
	if token.begins_with("affinity."):
		var candidate: String = token.trim_prefix("affinity.")
		if not candidate in _vocab.get("candidates", []):
			error = "unknown candidate in '%s'" % token
			return []
		return ["affinity", candidate]
	if token.begins_with("flag."):
		var flag_name: String = token.trim_prefix("flag.")
		flags_read.append(flag_name)
		return ["flag", flag_name]
	if _vocab.get("counters", {}).has(token):
		return ["counter", token]
	if _vocab.get("thresholds", {}).has(token):
		return ["num", _vocab.thresholds[token]]
	error = "unknown name '%s'" % token
	return []


func _eval(node: Array, store: AffinityStore) -> int:
	match node[0]:
		"num":
			return node[1]
		"affinity":
			return store.get_affinity(node[1])
		"flag":
			return 1 if store.has_flag(node[1]) else 0
		"counter":
			return store.get_counter(node[1])
		"not":
			return 0 if _truthy(_eval(node[1], store)) else 1
		"and":
			return 1 if _truthy(_eval(node[1], store)) and _truthy(_eval(node[2], store)) else 0
		"or":
			return 1 if _truthy(_eval(node[1], store)) or _truthy(_eval(node[2], store)) else 0
		"cmp":
			var left: int = _eval(node[2], store)
			var right: int = _eval(node[3], store)
			match node[1]:
				"==": return 1 if left == right else 0
				"!=": return 1 if left != right else 0
				">=": return 1 if left >= right else 0
				"<=": return 1 if left <= right else 0
				">": return 1 if left > right else 0
				_: return 1 if left < right else 0
	return 0


func _truthy(value: int) -> bool:
	return value != 0
