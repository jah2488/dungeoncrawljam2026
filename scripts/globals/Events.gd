extends Node

## Utility events
signal MouseCaptured
signal MouseReleased
signal ResumeGame
signal PauseGame

## Lifecycle events
signal GameStarted
signal GameOver
signal GameQuit

## Save events
signal SaveCompleted
signal LoadCompleted

## Scene events
signal SceneChangeStarted(scene_path: String)
signal SceneChangeCompleted(scene_path: String)

## Game Events
signal PlayerTurned(rot: float)
signal PlayerMoved(dir: int)
signal PlayerLocation(pos: Vector2i, rot: float)
signal PlayerInspected
signal PlayerDisarmed
signal PlayerAttacked
signal PlayerDefended
signal PlayerTakesDamage(amount: int, source: Interactable)
signal PlayerTriggerTrap(amount: int, source: Interactable)
signal PlayerHeals(amount: int, source: Interactable)
signal StartCombat
signal EndCombat


## Debug helper — logs signal emission with frame number, then emits it.
## Usage: Events.debug_emit(self, Events.GameStarted)
##        Events.debug_emit(self, Events.SceneChangeStarted, ["res://scenes/main.tscn"])
func debug_emit(sender: Variant, sig: Signal, args: Array = []) -> void:
    var frame: int = Engine.get_frames_drawn()
    var sender_name: String = sender.name if sender is Node else str(sender)
    print("[%d] Event: %s %s (from: %s)" % [frame, sig.get_name(), args, sender_name])
    match args.size():
        0:
            sig.emit()
        1:
            sig.emit(args[0])
        2:
            sig.emit(args[0], args[1])
        3:
            sig.emit(args[0], args[1], args[2])
