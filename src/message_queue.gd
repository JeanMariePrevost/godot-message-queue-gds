# MessageQueue.gd
## MessageQueue / "Command" queue system that can be used to queue up messages to be processed in order,
## pool, deduplicate, delay messages and more.

extends RefCounted
class_name MessageQueue

var messages: Array[Message] = []

## Default deduplication policy for messages in this queue.
## If true, only 1 message of any given id can exist in the queue at any time.
## Applies to messages with `deduplicate` set to `DEFAULT`.
var _deduplicate: bool = true
var deduplicate: bool:
    get:
        return _deduplicate
    set(value):
        _deduplicate = value
        if value:
            # Re-apply deduplication now since duplicates might have been introduced
            apply_deduplication()


## Enqueue a message to the back of the queue.
func enqueue(new_message: Message) -> void:
    var m_stage: int = new_message.stage
    var m_priority: int = new_message.priority
    var m_deduplicate: Message.DuplicatePolicy = new_message.deduplicate

    # Deduplication
    if m_deduplicate == Message.DuplicatePolicy.ALWAYS or (m_deduplicate == Message.DuplicatePolicy.DEFAULT and deduplicate):
        if has_message(new_message.id):
            return

    # Insertion at correct position
    for i in range(messages.size()):
        var existing_message: Message = messages[i]

        if m_stage < existing_message.stage or (m_stage == existing_message.stage and m_priority > existing_message.priority):
            messages.insert(i, new_message)
            return

    # If still not inserted, goes at the back
    messages.append(new_message)


## Total count of messages in the queue.
func size() -> int:
    return messages.size()


## True if the queue is empty.
func is_empty() -> bool:
    return messages.is_empty()


## Remove all messages from the queue.
func clear() -> void:
    messages.clear()


## Remove all messages of a given stage from the queue.
func remove_stage(stage: int) -> void:
    messages = messages.filter(func(m: Message) -> bool: return m.stage != stage)


## Remove all messages with a given id from the queue.
func remove_messages_with_id(id: String) -> void:
    messages = messages.filter(func(m: Message) -> bool: return m.id != id)


## Remove duplicate messages from the queue, regardless of the deduplication policy.
## Can optionally respect the "NEVER" deduplication policy set at the message level.
func remove_duplicates(respect_never_policy: bool = false) -> void:
    var seen: Dictionary = {}
    # iterate backwards to safely remove
    for i in range(messages.size() - 1, -1, -1):
        var msg: Message = messages[i]
        if (msg.deduplicate == Message.DuplicatePolicy.DEFAULT and seen.has(msg.id)) or (respect_never_policy and msg.deduplicate == Message.DuplicatePolicy.NEVER):
            messages.remove_at(i)
        else:
            seen[msg.id] = true


## Remove duplicate messages with a given id from the queue, regardless of the deduplication policy.
func remove_duplicates_with_id(id: String) -> void:
    for i in range(messages.size() - 1, -1, -1):
        var msg: Message = messages[i]
        if msg.id == id and msg.deduplicate == Message.DuplicatePolicy.DEFAULT:
            messages.remove_at(i)


## Get all unique stages that exist across the queue's messages.
func list_stages() -> Array[int]:
    # Build a dictionary to get all the unique stages
    # This avoids iterating over the entire queue multiple times
    var unique: Dictionary[int, bool] = {}
    for m in messages:
        unique[m.stage] = true
    var stages: Array[int] = unique.keys()
    stages.sort()
    return stages


## Returns (and removes) the next message in queue.
## (The message with the lowest stage, then highest priority)
func dequeue() -> Message:
    return null if messages.is_empty() else messages.pop_front()


## Returns (and removes) the next message for the given stage.
func dequeue_for_stage(stage: int) -> Message:
    for i in range(messages.size()):
        if messages[i].stage == stage:
            return messages.pop_at(i)
    return null


## Returns the next message in queue without removing it.
func peek() -> Message:
    return null if messages.is_empty() else messages[0]


## Returns the next message in queue for the given stage without removing it.
func peek_stage(stage: int) -> Message:
    for i in range(messages.size()):
        if messages[i].stage == stage:
            return messages[i]
    return null


## Checks whether a message with a given id is already in the queue.
## Note: does not consider other metadata like payload or priority.
func has_message(id: String) -> bool:
    for message in messages:
        if message.id == id:
            return true
    return false


## String representation of the queue (front displayed at the left).
func _to_string() -> String:
    ## TODO: Implement this properly
    return "MessageQueue(" + str(messages) + ")"

# =======================================
# Custom iterator implementation
# (To allow for-in loops)
# =======================================

# func _iter_init(_arg) -> bool:
#     _iter_index = 0
#     _iter_list = _data.slice(_head)
#     return _iter_index < _iter_list.size()

# func _iter_next(_arg) -> bool:
#     _iter_index += 1
#     return _iter_index < _iter_list.size()

# func _iter_get(_arg) -> Variant:
#     return _iter_list[_iter_index]

# # --- Internal helpers

# static func _is_iterable(v: Variant) -> bool:
#     if v is Array or v is Dictionary or v is String:
#         return true
#     if v is PackedByteArray or v is PackedInt32Array or v is PackedInt64Array:
#         return true
#     if v is PackedFloat32Array or v is PackedFloat64Array:
#         return true
#     if v is PackedStringArray or v is PackedVector2Array or v is PackedVector3Array:
#         return true
#     if v is PackedColorArray:
#         return true
#     if v is Object and v.has_method("_iter_init") and v.has_method("_iter_next") and v.has_method("_iter_get"):
#         return true
#     return false
