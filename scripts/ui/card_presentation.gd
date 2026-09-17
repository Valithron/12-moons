class_name MoonCardPresentation
extends RefCounted

const CARD_SCENE := "res://addons/card-framework/card.tscn"
const HAND_SCENE := "res://addons/card-framework/hand.tscn"
const PILE_SCENE := "res://addons/card-framework/pile.tscn"

static func create_card_node(definition: CardDefinition, parent: Node = null) -> Node:
	var card_node = load(CARD_SCENE).instantiate()
	card_node.card_name = definition.card_id
	card_node.card_info = definition.to_dict()
	card_node.set_meta("moon_card_id", definition.card_id)
	if parent != null:
		parent.add_child(card_node)
	return card_node

static func card_id_from_node(card_node: Node) -> String:
	if card_node.has_meta("moon_card_id"):
		return String(card_node.get_meta("moon_card_id"))
	return String(card_node.card_name)

static func create_hand_container(parent: Node = null) -> Node:
	var hand = load(HAND_SCENE).instantiate()
	if parent != null:
		parent.add_child(hand)
	return hand

static func create_pile_container(parent: Node = null) -> Node:
	var pile = load(PILE_SCENE).instantiate()
	if parent != null:
		parent.add_child(pile)
	return pile
