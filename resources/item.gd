extends Resource

class_name Item

@export var name := "Unnamed Item"
@export var desc := "You look at the item, it seems like it doesn't exist"
@export var icon: Texture2D

@export_group("Buying & Selling")
# For buying/selling
@export var buy_price := 10
@export var sale_price := 4

@export_group("Weapon Stats")
# Only relevant for weapons
@export var damage := 0
@export var damage_type := Game.DamageType.NORMAL
@export var charges := 0

@export_group("Consumable Stats")
# For multi-use items
@export var uses := 3

# Only relevant for health consumables...unless
@export var heal_amount := 0

# For refilling charges
@export var charges_restored := 0
@export var charges_type := Game.DamageType.NORMAL
