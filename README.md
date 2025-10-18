# MessageQueue.GDS - Traffic control for your main game events.

[![Godot 4.0+](https://img.shields.io/badge/Godot-4.5+-478CBF.svg)](https://godotengine.org) [![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg)](./LICENSE) [![Language: GDScript](https://img.shields.io/badge/Language-GDScript-orange.svg)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)


---

## Overview
A lightweight message queue for GDScript with a few extra capabilities.

Its main purpose is to act as a **buffer** for collecting events or requests during a frame, then **sorting**, **deduplicating**, and **processing** them safely at the end of that frame.

It supports double-buffering, delayed scheduling (e.g. add an action for the next frame), automatic deduplication, and priority/stage ordering, making it easy to manage complex event dispatching in a deterministic way across frames.


## Features
- **Buffered processing** - freeze the queue while draining to prevent reentrancy and loops.
- **Delayed scheduling** - schedule messages to be enqueued after a delay in real time or frame count.
- **Priority and stage ordering** - automatically sorts on enqueue.
- **Deduplication** - optional prevention of duplicate messages.


---

## Quick Start

### Basic Usage

```gdscript
# Create an instance of MessageQueue
var queue := MessageQueue.new()

# Enqueue messages
queue.enqueue(Message.new("player_damaged"))
queue.enqueue(Message.new("enemy_defeated"))

# Process messages
while not queue.is_empty():
    var msg := queue.dequeue()
    print("Processing: ", msg.id)
```

Messages can also carry a simple payload, which can be any single value or object:

```gdscript
var message_with_int_payload := Message.new("player_exp_gain", 25)
var message_with_dict_payload := Message.new("player_stats_updated", {"hp": 100, "mp": 72})

queue.enqueue(message_with_int_payload)
queue.enqueue(message_with_dict_payload)

var msg1: Message = queue.dequeue()  # First in, the one with the int payload
var msg2: Message = queue.dequeue()  # Second in, the one with the dict payload

print(msg1.payload)  # Prints 25
print(msg2.payload)  # Prints {"hp": 100, "mp": 72}
```

### Ordering: Priority and Stages

Two sorting mechanisms are offered: **priority** and **stages**
Higher priority messages are processed first.
Stages function in reverse (lower values go first) and can be used to _group_ messages, either to prioritize messages against specific messages of the same stage, or to be able to process them as distinct groups or phases, for example during `process_frame`, during `deferred` calls, and at `frame_post_draw`.


#### Priority Ordering

```gdscript
var urgent: Message = Message.new("critical_action")
urgent.priority = 10

var important: Message = Message.new("important_action")
important.priority = 5

var normal: Message = Message.new("normal_action") # Default priority is 0

var unimportant: Message =  Message.new("unimportant_action")
normal.priority = -1 # Negative values are also allowed


# Order of insertion will not affect results here
queue.enqueue(normal)
queue.enqueue(urgent)
queue.enqueue(unimportant)
queue.enqueue(important)

queue.dequeue()  # Returns "critical_action" Message (priority 10)
queue.dequeue()  # Returns "important_action" Message (priority 5)
queue.dequeue()  # Returns "normal_action" Message (priority 0)
queue.dequeue()  # Returns "unimportant_action" Message (priority -1)
```

#### Stage-Based Ordering

Stages let you group messages into logical phases (where lower stage = processed first) and apply ordering on top of priority:

```gdscript
var default_stage_message: Message = Message.new("default_stage_action")  # Default stage is 0

var first_stage_message: Message = Message.new("stage_1_action")
first_stage_message.stage = 1

var second_stage_message1: Message = Message.new("stage_2_action_A")
second_stage_message1.stage = 2
second_stage_message1.priority = 2

var second_stage_message2: Message = Message.new("stage_2_action_B")
second_stage_message2.stage = 2
second_stage_message2.priority = 5

# Order of insertion will not affect results here either
queue.enqueue(default_stage_message)
queue.enqueue(first_stage_message)
queue.enqueue(second_stage_message1)
queue.enqueue(second_stage_message2)

# Results will be in the order of stage, then priority
queue.dequeue()  # Returns "default_stage_action" Message (stage 0)
queue.dequeue()  # Returns "stage_1_action" Message (stage 1)
queue.dequeue()  # Returns "stage_2_action_B" Message (stage 2, priority 5)
queue.dequeue()  # Returns "stage_2_action_A" Message (stage 2, priority 2)

# It is also possible to dequeue messages for a specific stage
# For example, assuming we hadn't already dequeued them:
queue.dequeue_for_stage(2)  # Returns "stage_2_action_B" Message (stage 2, priority 5)
queue.dequeue_for_stage(2)  # Returns "stage_2_action_A" Message (stage 2, priority 2)
```

### Deduplication

You can easily prevent duplicate entries at the queue level:

```gdscript
queue.allow_duplicates = false  # Prevent duplicates globally

queue.enqueue(Message.new("update_score"))
queue.enqueue(Message.new("update_score"))  # Dropped (duplicate id)
queue.enqueue(Message.new("update_score"))  # Dropped (duplicate id)

queue.size()  # Returns 1
```

Per-message duplicate control can be used to prevent duplicates for only specific messages, or to _allow_ duplicates for only certain ones.

For example we could prevent duplicates globally, except for specific messages:

```gdscript
queue.allow_duplicates = false  # Prevent duplicates globally

var allowed_dupe_message1: Message = Message.new("damage_player")
allowed_dupe_message1.allow_duplicates = Message.DuplicatePolicy.FORCE_ALLOW_DUPLICATES # Allow duplicates for this message, regardless of queue.allow_duplicates

var allowed_dupe_message2: Message = Message.new("damage_player")
allowed_dupe_message2.allow_duplicates = Message.DuplicatePolicy.FORCE_ALLOW_DUPLICATES # Allow duplicates for this message, regardless of queue.allow_duplicates


queue.enqueue(Message.new("update_score"))
queue.enqueue(Message.new("update_score"))  # Dropped (queue.allow_duplicates = false and duplicate id)
queue.enqueue(allowed_dupe_message1)
queue.enqueue(allowed_dupe_message2)  # Both kept, even if queue.allow_duplicates = false
```

Or we could allow duplicates by default, but force deduplication for specific messages that shouldn't happen more than once:

```gdscript
queue = MessageQueue.new() # Duplicates are allowed by default
queue.allow_duplicates = true # But you could also allow them explicitly

var no_dupes_allowed_message1: Message = Message.new("game_over")
no_dupes_allowed_message1.allow_duplicates = Message.DuplicatePolicy.FORCE_NO_DUPLICATES # Prevent duplicates for this message, regardless of queue.allow_duplicates

var no_dupes_allowed_message2: Message = Message.new("game_over")
no_dupes_allowed_message2.allow_duplicates = Message.DuplicatePolicy.FORCE_NO_DUPLICATES # Prevent duplicates for this message, regardless of queue.allow_duplicates

queue.enqueue(Message.new("update_score"))
queue.enqueue(Message.new("update_score"))  # Both kept since queue.allow_duplicates = true
queue.enqueue(no_dupes_allowed_message1)
queue.enqueue(no_dupes_allowed_message2)  # Dropped even though queue.allow_duplicates = true, because the message's policy is FORCE_NO_DUPLICATES
```

### Delayed Enqueues / Message Scheduling

Messages that need to be added now, but not actually be processed until later can be scheduled with "enquued_after_x":

```gdscript
# Schedule after a real-time delay (milliseconds)
queue.enqueue_after_ms(Message.new("explosion"), 1000)  # Will automatically be enqueued after 1 second

# Scedule after a number of process frames
queue.enqueue_after_frames(Message.new("next_turn"), 1)  # Will automatically be enqueued on the next frame

queue.dequeue()  # Will still returns null, the messages are _scheduled_, but not yet _enqueued_

# We can see if any messages of a certain id are scheduled
queue.is_scheduled(Message.new("explosion"))  # Returns true

# And we can remove specific or all scheduled messages
queue.remove_scheduled_message(Message.new("explosion"))  # Removes the scheduled message
queue.remove_scheduled_messages()  # Removes all scheduled messages
```

### Freeze/Unfreeze (Double Buffering)

If you wish to prevent changes in the queue or issues with reentrancy and potential loops, you can "freeze" the queue during processing. This prevents new message from being added to the queue, either by buffering them until processing is complete, or by dropping them entirely:

```gdscript
queue.enqueue(Message.new("i_will_be_processed"))

# Freeze the queue, moving all subsequent enqueue calls to a separate buffer
queue.freeze()

queue.enqueue(Message.new("i_will_be_buffered"))

# Process all messages safely
while not queue.is_empty():
    var msg := queue.dequeue()
    print(msg.id)  # We will only see "i_will_be_processed"

# Unfreeze - buffered messages are now enqueued
queue.unfreeze()

# At this point, "i_will_be_buffered" is now in the queue
```

Using freeze_blocking completely blocks new enqueue calls by dropping the messages instead of buffering:

```gdscript
queue.freeze_blocking()  # No new enqueues processed

queue.enqueue(Message.new("dropped"))  # Silently dropped

queue.unfreeze()  # Returns to normal
```

### Removal Operations

Aside from dequeue, there are various queue manipulation functions that can be used to process the queue:

```gdscript
# Remove all messages in a given stage
queue.remove_messages_in_stage(1)

# Remove all messages with a specific ID
queue.remove_messages_with_id("old_event")

# Remove duplicates manually, regardless of settings
queue.remove_duplicates()
```

---

## Installation

Simply copy the `addons/lbg.godot.gdscript.messagequeue/` folder into your project.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Author

**Jean-Marie Prévost**
[https://github.com/JeanMariePrevost](https://github.com/JeanMariePrevost)
