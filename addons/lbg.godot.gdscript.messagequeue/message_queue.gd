# MessageQueue.gd
## MessageQueue / "Command" queue system that can be used to queue up _messages to be processed in order,
## pool, deduplicate, delay _messages and more.

extends RefCounted
class_name MessageQueue

enum QueueState {
    OPEN,  ## Accepts all modifications (enqueue, dequeue, etc.)
    SEALED_BUFFERING,  ## New enqueues are accepted, but buffered to a separate queue until the queue is unsealed
    SEALED_DROPPING,  ## New enqueues are dropped
}

## The internal list of _messages in the queue.
var _messages: Array[Message]

## The internal list of messages that have been added to the queue while _state == QueueState.DETACHED.
var _sealed_state_message_buffer: Array[Message]

## The internal list of messages "queued to be enqueued"
## E.g. messages added through `enqueue_after_ms` or `enqueue_after_frames`
var _scheduled_messages: Array[Message]

## Default duplicate handling policy for _messages in this queue.
## If false, only 1 message of any given id can exist in the queue at any time (duplicates are prevented).
## If true, messages with the same id can coexist in the queue.
## Applies to _messages with `allow_duplicates` set to `FOLLOW_QUEUE_POLICY`.
var _allow_duplicates: bool = true
var allow_duplicates: bool:
    get:
        return _allow_duplicates
    set(value):
        _allow_duplicates = value
        if not _allow_duplicates:
            # Re-apply deduplication now since duplicates might have been introduced
            remove_duplicates(true)

## Whether the queue is currently seal and pushing new enqueues to a buffer or dropping them entirely.
var _state: QueueState = QueueState.OPEN

## Whether to warn when a message is dropped from being enqueued while the queue is CLOSED.
var warn_on_sealed_closed_enqueue: bool = true


## Creates a new empty MessageQueue.
func _init() -> void:
    _messages = []
    _scheduled_messages = []
    _sealed_state_message_buffer = []
    Engine.get_main_loop().process_frame.connect(_on_process_frame)


## Internally used for delays and other self-managed features.
func _on_process_frame() -> void:
    _process_scheduled_messages()


## Checks if any scheduled messages are due to be enqueued and enqueues them if so.
func _process_scheduled_messages() -> void:
    ## Go through the scheduled messages and enqueue them if the time has come.
    for i in range(_scheduled_messages.size() - 1, -1, -1):  # iterate backwards to safely remove
        var message: Message = _scheduled_messages[i]
        if message.internal_enqueue_after_timestamp >= 0 and message.internal_enqueue_after_timestamp <= Time.get_ticks_msec():
            enqueue(message)
            _scheduled_messages.remove_at(i)
            continue
        if message.internal_enqueue_after_frame_stamp >= 0 and message.internal_enqueue_after_frame_stamp <= Engine.get_process_frames():
            enqueue(message)
            _scheduled_messages.remove_at(i)
            continue


## Enqueue a message to the back of the queue.
## If the queue is DETACHED, the message is buffered to a separate queue until the queue is OPEN.
## If the queue is CLOSED, the message will be dropped.
func enqueue(new_message: Message) -> void:
    if _state == QueueState.SEALED_BUFFERING:
        _sealed_state_message_buffer.append(new_message)
        return
    if _state == QueueState.SEALED_DROPPING:
        if warn_on_sealed_closed_enqueue:
            push_warning("Tried to enqueue a message while the queue is CLOSED. Message was dropped. Message: ", new_message.id)
        return

    var m_stage: int = new_message.stage
    var m_priority: int = new_message.priority
    var m_allow_duplicates: Message.DuplicatePolicy = new_message.allow_duplicates

    # Deduplication check
    if m_allow_duplicates == Message.DuplicatePolicy.FORCE_NO_DUPLICATES or (m_allow_duplicates == Message.DuplicatePolicy.FOLLOW_QUEUE_POLICY and not allow_duplicates):
        if has_message(new_message.id):
            return

    # Insertion at correct position
    for i in range(_messages.size()):
        var existing_message: Message = _messages[i]

        if m_stage < existing_message.stage or (m_stage == existing_message.stage and m_priority > existing_message.priority):
            _messages.insert(i, new_message)
            return

    # If still not inserted, goes at the back
    _messages.append(new_message)


## Buffers a message to be enqueued after a number of milliseconds, in real time.
func enqueue_after_ms(new_message: Message, ms: int) -> void:
    new_message.internal_enqueue_after_timestamp = Time.get_ticks_msec() + ms
    _scheduled_messages.append(new_message)


## Buffers a message to be enqueued after a number of frames, in engine time.
func enqueue_after_frames(new_message: Message, frames: int) -> void:
    new_message.internal_enqueue_after_frame_stamp = Engine.get_process_frames() + frames
    _scheduled_messages.append(new_message)


## Total count of _messages in the queue.
func size() -> int:
    return _messages.size()


## True if the queue is empty.
## Note: does not consider scheduled messages.
func is_empty() -> bool:
    return _messages.is_empty()


## Remove all _messages from the queue.
## Does not affect scheduled messages.
func clear() -> void:
    _messages.clear()


## Clears all scheduled messages.
## Does not affect the main queue.
func clear_scheduled_messages() -> void:
    _scheduled_messages.clear()


## Remove all _messages of a given stage from the queue.
## Does not affect scheduled messages.
func remove_messages_in_stage(stage: int) -> void:
    _messages = _messages.filter(func(m: Message) -> bool: return m.stage != stage)


## Remove all scheduled messages of a given stage that aren't yet enqueued.
## Does not affect the main queue.
func remove_scheduled_messages_in_stage(stage: int) -> void:
    _scheduled_messages = _scheduled_messages.filter(func(m: Message) -> bool: return m.stage != stage)


## Remove all _messages with a given id from the queue.
## Does not affect scheduled messages.
func remove_messages_with_id(id: String) -> void:
    _messages = _messages.filter(func(m: Message) -> bool: return m.id != id)


## Remove all scheduled messages with a given id that aren't yet enqueued.
## Does not affect the main queue.
func remove_scheduled_messages_with_id(id: String) -> void:
    _scheduled_messages = _scheduled_messages.filter(func(m: Message) -> bool: return m.id != id)


## Remove duplicate messages from the queue, regardless of the global duplicate policy.
## Can optionally respect the "FORCE_ALLOW_DUPLICATES" policy set at the message level.
## If respect_allow_duplicates_policy is true, messages with FORCE_ALLOW_DUPLICATES policy will not be removed.
## Does not affect scheduled messages, which technically aren't part of the queue yet.
func remove_duplicates(respect_allow_duplicates_policy: bool = false) -> void:
    var seen: Dictionary = {}
    # iterate backwards to safely remove
    for i in range(_messages.size() - 1, -1, -1):
        var msg: Message = _messages[i]
        if seen.has(msg.id):
            remove_duplicates_with_id(msg.id, respect_allow_duplicates_policy)
            continue
        seen[msg.id] = true


## Remove duplicate _messages with a given id from the queue, regardless of the global duplicate policy.
## Can optionally respect the "FORCE_ALLOW_DUPLICATES" policy set at the message level.
## If respect_allow_duplicates_policy is true, messages with FORCE_ALLOW_DUPLICATES policy will not be removed.
## Does not affect scheduled messages, which technically aren't part of the queue yet.
func remove_duplicates_with_id(id: String, respect_allow_duplicates_policy: bool = false) -> void:
    var have_force_allow_to_keep: bool = false

    # First detect if we have any FORCE_ALLOW_DUPLICATES _messages to keep if we need to respect the policy
    if respect_allow_duplicates_policy:
        for msg in _messages:
            if msg.id == id and msg.allow_duplicates == Message.DuplicatePolicy.FORCE_ALLOW_DUPLICATES:
                have_force_allow_to_keep = true
                break

    # Iterate backwards so we can remove safely
    var seen := false
    for i in range(_messages.size() - 1, -1, -1):
        var msg: Message = _messages[i]
        if msg.id != id:
            continue

        if respect_allow_duplicates_policy and have_force_allow_to_keep:
            # Keep all FORCE_ALLOW_DUPLICATES, remove everything else
            if msg.allow_duplicates != Message.DuplicatePolicy.FORCE_ALLOW_DUPLICATES:
                _messages.remove_at(i)
            continue

        # Normal deduplication (remove all but one)
        if not seen:
            # First one encountered (latest in queue) is kept
            seen = true
        else:
            _messages.remove_at(i)


## Get all unique stages that exist across the queue's _messages.
func list_stages() -> Array[int]:
    # Build a dictionary to get all the unique stages
    # This avoids iterating over the entire queue multiple times
    var unique: Dictionary[int, bool] = {}
    for m in _messages:
        unique[m.stage] = true
    var stages: Array[int] = unique.keys()
    stages.sort()
    return stages


## Returns (and removes) the next message in queue.
## (The message with the lowest stage, then highest priority)
func dequeue() -> Message:
    return null if _messages.is_empty() else _messages.pop_front()


## Returns (and removes) the next message for the given stage.
func dequeue_for_stage(stage: int) -> Message:
    for i in range(_messages.size()):
        if _messages[i].stage == stage:
            return _messages.pop_at(i)
    return null


## Returns the next message in queue without removing it.
func peek() -> Message:
    return null if _messages.is_empty() else _messages[0]


## Returns the next message in queue for the given stage without removing it.
func peek_stage(stage: int) -> Message:
    for i in range(_messages.size()):
        if _messages[i].stage == stage:
            return _messages[i]
    return null


## Checks whether a message with a given id is already in the queue.
## Note: does not consider other metadata like payload or priority.
func has_message(id: String) -> bool:
    for message in _messages:
        if message.id == id:
            return true
    return false


## Checks whether a message with a given id is in the scheduled messages.
func has_scheduled_message(id: String) -> bool:
    for message in _scheduled_messages:
        if message.id == id:
            return true
    return false


## Isolates the queue by buffering new enqueues separately until the queue is re-opened.
## The queue can still be dequeued from.
## For example, if you want to process all messages received in the last frame, you can seal, process the queue, and then reopen.
## Messages can still be scheduled, but will not be enqueued until the queue is reopened.
func seal() -> void:
    _state = QueueState.SEALED_BUFFERING


## Like `seal()`, but drops all new enqueues instead of buffering them.
## Messages can still be scheduled, but will be dropped if they are due to be enqueued while in this state.
func seal_closed() -> void:
    _state = QueueState.SEALED_DROPPING


## Reopens the queue, allowing new enqueues to be processed normally.
## This is the default state.
func unseal() -> void:
    _state = QueueState.OPEN

    ## Now try to enqueue all the buffered messages
    for message in _sealed_state_message_buffer:
        enqueue(message)

    _sealed_state_message_buffer.clear()

    # And also check if any scheduled messages are due to be enqueued
    _process_scheduled_messages()


## String representation of the queue (front displayed at the left).
func _to_string() -> String:
    ## TODO: Implement this properly
    return "MessageQueue(" + str(_messages) + ")"

# =======================================
# Custom iterator implementation
# (To allow for-in loops)
# =======================================

# TODO: Implement iteration? Not relevant for a message queue? Or should it dequeue messages as it iterates?

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
