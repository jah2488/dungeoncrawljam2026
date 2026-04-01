extends Node

var group_pool = {}

func add_item_to_group(group_id, item):
    if group_pool.has(group_id):
        group_pool[group_id].append(item)
    else:
        group_pool[group_id] = [item]


func get_items_from_group(group_id) -> Array:
    return group_pool[group_id]


func trigger_items_in_group(group_id):
    for item in group_pool[group_id]:
        if item.is_triggerable:
            item.trigger()


func has_triggerable_items(group_id) -> bool:
    return group_pool[group_id].any(func(item): return item.is_triggerable)
