extends Node

const SAVE_KEY = "post_processing"

@onready var crt_rect: ColorRect = $CRTLayer/CRT
@onready var vhs_rect: ColorRect = $VHSLayer/VHS


func _ready() -> void:
    _load_settings()


func set_crt_enabled(enabled: bool) -> void:
    crt_rect.visible = enabled
    _save_settings()


func set_vhs_enabled(enabled: bool) -> void:
    vhs_rect.visible = enabled
    _save_settings()


func is_crt_enabled() -> bool:
    return crt_rect.visible


func is_vhs_enabled() -> bool:
    return vhs_rect.visible


func _load_settings() -> void:
    var saved: Dictionary = SaveManager.get_data(SAVE_KEY, { })
    crt_rect.visible = saved.get("crt", false)
    vhs_rect.visible = saved.get("vhs", false)


func _save_settings() -> void:
    SaveManager.set_data(
        SAVE_KEY,
        {
            "crt": crt_rect.visible,
            "vhs": vhs_rect.visible,
        },
    )
