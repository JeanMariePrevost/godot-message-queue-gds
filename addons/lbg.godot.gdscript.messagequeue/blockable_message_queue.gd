# BlockableMessageQueue.gd
## A MessageQueue that can be blocked, making it so that dequeuing is blocked until the queue is unblocked.
##
## Useful to have "blocking messages" that prevent further processing of the queue until the blocking is lifted.
##
## For example, if you want to fully process a given message while preventing the next message from being processed,
## and have that "unblocking" logic be up to the caller, you can use this class.

extends MessageQueue
class_name BlockableMessageQueue

## The list of block tokens currently blocking this queue.
var _block_tokens: Array[BlockableMessageQueueBlockToken]


## Prevents further dequeuing of messages until the token is unblocked.
## Other functions of the queue are still available, but dequeuing wil behave as though the queue is empty.
##
## You can manually unblock the queue through `unblock()` or set a timeout or expiration predicate to automatically remove this particular block.
##
## @param key The key of the token.
## @param expiration_predicate The predicate that will be called to determine if the token should be expired.
## @param timeout_ms The timeout in milliseconds when the token will expire, checked against Time.get_ticks_msec(). If 0, the token will never expire.
## @param timeout_frames The timeout in frames when the token will expire, checked against Engine.get_process_frames(). If 0, the token will never expire.
##
## Note: If either timeout runs out or the expiration_predicate returns true, the token is removed (i.e. OR, not AND)
func block(key: String = "", timeout_ms: int = 0, timeout_frames: int = 0, expiration_predicate: Callable = Callable()) -> void:
    _block_tokens.append(BlockableMessageQueueBlockToken.new(key, timeout_ms, timeout_frames, expiration_predicate))


## Unblocks all tokens currently blocking this queue.
func force_unblock() -> void:
    _block_tokens.clear()


## Unblocks all tokens that have a given key.
func unblock(key: String = "") -> void:
    for i in range(_block_tokens.size() - 1, -1, -1):
        if _block_tokens[i].key == key:
            _block_tokens.remove_at(i)


## Unblocks the given token by reference.
func unblock_by_ref(token: BlockableMessageQueueBlockToken) -> void:
    _block_tokens.erase(token)


## Checks if a given key is currently blocking this queue.
func is_blocked_by_key(key: String) -> bool:
    for token in _block_tokens:
        if token.key == key:
            return true
    return false


## Checks if a given token is currently blocking this queue.
func is_blocked_by_ref(token: BlockableMessageQueueBlockToken) -> bool:
    return _block_tokens.has(token)


## Checks if this queue is currently blocked.
func is_blocked() -> bool:
    return _block_tokens.size() > 0


## Checks if this queue is currently empty or blocked.
## Special case for the BlockableMessageQueue, since it can be not empty but blocked, in which case it would _still_ return null when dequeuing.
func is_empty_or_blocked() -> bool:
    return is_blocked() or _messages.is_empty()


## Returns (and removes) the next message in queue.
## (The message with the lowest stage, then highest priority)
##
## Note: If the queue is blocked, this will return null even if there are messages in the queue.
func dequeue() -> Message:
    return null if is_blocked() or _messages.is_empty() else _messages.pop_front()


## Returns (and removes) the next message for the given stage.
##
## Note: If the queue is blocked, this will return null even if there are messages in the queue.
func dequeue_for_stage(stage: int) -> Message:
    if is_blocked():
        return null

    for i in range(_messages.size()):
        if _messages[i].stage == stage:
            return _messages.pop_at(i)
    return null
