# BlockableMessageQueueBlockToken.gd
## A token that represents a "lock" on a BlockableMessageQueue.

extends RefCounted
class_name BlockableMessageQueueBlockToken

var key: String  ## An "id" for removing the token from the queue.
var expiration_predicate: Callable  ## A predicate that will be called to determine if the token should be expired.
var timeout_timestamp: int = 0  ## The timestamp when the token will expire, checked against Time.get_ticks_msec()
var timeout_framestamp: int = 0  ## The frame when the token will expire, checked against Engine.get_process_frames()


## Creates a new BlockableMessageQueueBlockToken.
## @param key The key of the token.
## @param expiration_predicate The predicate that will be called to determine if the token should be expired.
## @param timeout_ms The timeout in milliseconds when the token will expire, checked against Time.get_ticks_msec(). If 0, the token will never expire.
## @param timeout_frames The timeout in frames when the token will expire, checked against Engine.get_process_frames(). If 0, the token will never expire.
##
## Note: If either timeout runs out or the expiration_predicate returns true, the token is removed (i.e. OR, not AND)
func _init(key: String = "", timeout_ms: int = 0, timeout_frames: int = 0, expiration_predicate: Callable = Callable()) -> void:
    self.key = key
    self.expiration_predicate = expiration_predicate

    # Check the predicate immediately and use it as an opportunity to validate its return type
    if expiration_predicate.is_valid():
        var result: bool = expiration_predicate.call()
        if not result is bool:
            push_error("Expiration predicate must return a boolean")
            return

    if timeout_ms > 0:
        self.timeout_timestamp = Time.get_ticks_msec() + timeout_ms
    else:
        self.timeout_timestamp = 0

    if timeout_frames > 0:
        self.timeout_framestamp = Engine.get_process_frames() + timeout_frames
    else:
        self.timeout_framestamp = 0


## Checks if the token is expired according to its timeouts and expiration predicate.
## Note: Does not remove the token from the queue, only checks if it is expired.
func is_expired() -> bool:
    if expiration_predicate.is_valid():
        print("Token expired by predicate? ", bool(expiration_predicate.call()))
        return bool(expiration_predicate.call())

    print("Current time: ", Time.get_ticks_msec(), " vs timeout_timestamp: ", timeout_timestamp)
    print("Current frames: ", Engine.get_process_frames(), " vs timeout_framestamp: ", timeout_framestamp)
    print("Token expired by timeout_ms? ", timeout_timestamp > 0 and Time.get_ticks_msec() >= timeout_timestamp)
    print("Token expired by timeout_frames? ", timeout_framestamp > 0 and Engine.get_process_frames() >= timeout_framestamp)
    return (timeout_timestamp > 0 and Time.get_ticks_msec() >= timeout_timestamp) or (timeout_framestamp > 0 and Engine.get_process_frames() >= timeout_framestamp)
