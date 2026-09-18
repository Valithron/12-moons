class_name ModifierResalePolicy
extends RefCounted

## The sole authoritative resale calculation for shop sales, reward replacement,
## and emergency liquidation. Presentation may display this quote but never
## supplies or mutates it.

static func quote(instance_data: Dictionary, registry: ModifierRegistry) -> int:
	if instance_data.is_empty() or registry == null:
		return -1
	var definition_id := String(instance_data.get("definition_id", ""))
	var definition := registry.get_definition(definition_id)
	if definition == null or not definition.sellable:
		return -1
	var source := String(instance_data.get("source", ""))
	if source == "shop":
		return floori(maxi(0, int(instance_data.get("purchase_price", 0))) / 2.0)
	var base_price := int(instance_data.get("base_shop_price", definition.base_shop_price))
	return floori(maxi(0, base_price) / 2.0)

static func salvage_quote(instance_data: Dictionary, registry: ModifierRegistry) -> int:
	## Salvage always uses the definition's base shop value, including for a
	## previously purchased modifier. It is distinct from shop resale, which
	## uses the actual paid price for shop acquisitions.
	if instance_data.is_empty() or registry == null:
		return -1
	var definition := registry.get_definition(String(instance_data.get("definition_id", "")))
	if definition == null or not definition.sellable:
		return -1
	var base_price := int(instance_data.get("base_shop_price", definition.base_shop_price))
	return floori(maxi(0, base_price) / 2.0)
