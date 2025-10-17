# Message.gd
## Simple data object that holds the data for a message.

extends RefCounted
class_name Message

enum DuplicatePolicy { DEFAULT, ALWAYS, NEVER }

## The "kind of message", the "command" or "action" intended.
## E.g. "end_turn", "tutorial_screen_1_3", "game_over"
var id: String

## An optional variant payload of data that can be used to pass data to the message.
## Use a custom object or dictionary if you need to pass more than a single value.
var payload: Variant

## The priority of the message within its phase. Higher priority messages are processed first.
## Note that priority applies _within_ a stage if stages are used.
var priority: int = 0

## Optional additional priority / grouping of messages. _Lower_ stages are processed first.
## Stage applies before priority and can be used to group messages into logical steps.
## E.g. you could use this for intra-frame timing as "process_frame = 0", "deferred = 1", "pre_draw = 2", "post_draw = 3".
var stage: int = 0

## Whether multiple messages with the same id should be deduplicated.
## DEFAULT follows the queue's deduplication policy.
## ALWAYS forces deduplication regardless of the queue's policy.
## NEVER disables deduplication regardless of the queue's policy.
var deduplicate: DuplicatePolicy = DuplicatePolicy.DEFAULT

## INTERNAL USE ONLY: Defines a timestamp in relative to `Time.get_ticks_msec()` after which the message should be enqueued.
## For example, to immediately prepare a message that should only be processed after 1 second.
## -1 is the default "not set" value.
var internal_enqueue_after_timestamp: int = -1

## INTERNAL USE ONLY: Defines a frame stamp in `Engine.get_process_frames()` after which the message should be enqueued.
## For example, to immediately prepare a message that should only be processed on the next frame.
## -1 is the default "not set" value.
var internal_enqueue_after_frame_stamp: int = -1


## Creates a new message with the given id and optional payload.
## @param id The id of the message (e.g. "end_turn", "tutorial_screen_1_3", "game_over").
## @param payload The optional payload of the message (e.g. a single value, a dictionary or a custom object).
func _init(m_id: String, m_payload: Variant = null):
    id = m_id
    payload = m_payload
