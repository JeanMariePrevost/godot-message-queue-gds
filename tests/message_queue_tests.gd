extends GDTestCase

# Note: Mostly AI-generated, some manually verified.

# =============================================================================
# MessageQueue Basic Operations Tests
# =============================================================================


func test_queue_creation() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    return assert_true(queue != null and queue.is_empty() and queue.size() == 0, "Expected new queue to be empty with size 0")


func test_queue_default_deduplicate_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    return assert_true(queue.deduplicate == true, "Expected queue's default deduplicate to be true")


func test_queue_enqueue_single_message() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("msg1")
    queue.enqueue(message)
    return assert_true(queue.size() == 1 and not queue.is_empty(), "Expected queue to have size 1 after enqueue")


func test_queue_enqueue_multiple_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))
    queue.enqueue(Message.new("msg3"))
    return assert_equal(3, queue.size(), "Expected queue to have 3 messages")


func test_queue_clear() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))
    queue.clear()
    return assert_true(queue.is_empty() and queue.size() == 0, "Expected queue to be empty after clear")


func test_queue_has_message() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))
    return assert_true(queue.has_message("msg1") and queue.has_message("msg2") and not queue.has_message("msg3"), "Expected has_message to correctly identify existing messages")


# =============================================================================
# MessageQueue Dequeue and Peek Tests
# =============================================================================


func test_queue_dequeue_empty() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var result: Message = queue.dequeue()
    return assert_null(result, "Expected dequeue from empty queue to return null")


func test_queue_peek_empty() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var result: Message = queue.peek()
    return assert_null(result, "Expected peek on empty queue to return null")


func test_queue_dequeue_single() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("msg1")
    queue.enqueue(message)
    var result: Message = queue.dequeue()
    return assert_true(result != null and result.id == "msg1" and queue.is_empty(), "Expected dequeue to return the message and leave queue empty")


func test_queue_peek_does_not_remove() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    var first_peek: Message = queue.peek()
    var second_peek: Message = queue.peek()
    return assert_true(
        first_peek != null and second_peek != null and first_peek.id == "msg1" and second_peek.id == "msg1" and queue.size() == 1, "Expected peek to not remove message from queue"
    )


func test_queue_fifo_order() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))
    queue.enqueue(Message.new("msg3"))

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()

    return assert_true(first.id == "msg1" and second.id == "msg2" and third.id == "msg3", "Expected messages to be dequeued in FIFO order")


# =============================================================================
# MessageQueue Priority Tests
# =============================================================================


func test_queue_priority_ordering() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg_low: Message = Message.new("low")
    msg_low.priority = 1

    var msg_high: Message = Message.new("high")
    msg_high.priority = 10

    var msg_mid: Message = Message.new("mid")
    msg_mid.priority = 5

    queue.enqueue(msg_low)
    queue.enqueue(msg_high)
    queue.enqueue(msg_mid)

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()

    return assert_true(first.id == "high" and second.id == "mid" and third.id == "low", "Expected messages to be dequeued in priority order (highest first)")


func test_queue_priority_with_same_values() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.priority = 5

    var msg2: Message = Message.new("msg2")
    msg2.priority = 5

    var msg3: Message = Message.new("msg3")
    msg3.priority = 5

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()

    return assert_true(first.id == "msg1" and second.id == "msg2" and third.id == "msg3", "Expected messages with same priority to maintain FIFO order")


# =============================================================================
# MessageQueue Stage Tests
# =============================================================================


func test_queue_stage_ordering() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg_stage2: Message = Message.new("stage2")
    msg_stage2.stage = 2

    var msg_stage0: Message = Message.new("stage0")
    msg_stage0.stage = 0

    var msg_stage1: Message = Message.new("stage1")
    msg_stage1.stage = 1

    queue.enqueue(msg_stage2)
    queue.enqueue(msg_stage0)
    queue.enqueue(msg_stage1)

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()

    return assert_true(first.id == "stage0" and second.id == "stage1" and third.id == "stage2", "Expected messages to be dequeued in stage order (lowest stage first)")


func test_queue_stage_and_priority_ordering() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    # Stage 0, priority 1
    var msg1: Message = Message.new("s0p1")
    msg1.stage = 0
    msg1.priority = 1

    # Stage 0, priority 10
    var msg2: Message = Message.new("s0p10")
    msg2.stage = 0
    msg2.priority = 10

    # Stage 1, priority 100
    var msg3: Message = Message.new("s1p100")
    msg3.stage = 1
    msg3.priority = 100

    # Stage 1, priority 1
    var msg4: Message = Message.new("s1p1")
    msg4.stage = 1
    msg4.priority = 1

    queue.enqueue(msg3)
    queue.enqueue(msg1)
    queue.enqueue(msg4)
    queue.enqueue(msg2)

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()
    var fourth: Message = queue.dequeue()

    return assert_true(
        first.id == "s0p10" and second.id == "s0p1" and third.id == "s1p100" and fourth.id == "s1p1",
        "Expected stage to be primary sort (lowest first), then priority (highest first)"
    )


func test_queue_list_stages_empty() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var stages: Array[int] = queue.list_stages()
    return assert_true(stages.is_empty(), "Expected empty queue to have no stages")


func test_queue_list_stages_single() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var msg: Message = Message.new("msg")
    msg.stage = 3
    queue.enqueue(msg)
    var stages: Array[int] = queue.list_stages()
    return assert_true(stages.size() == 1 and stages[0] == 3, "Expected list_stages to return [3]")


func test_queue_list_stages_multiple() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 2

    var msg2: Message = Message.new("msg2")
    msg2.stage = 0

    var msg3: Message = Message.new("msg3")
    msg3.stage = 2  # Duplicate stage

    var msg4: Message = Message.new("msg4")
    msg4.stage = 5

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)

    var stages: Array[int] = queue.list_stages()

    return assert_true(stages.size() == 3 and stages[0] == 0 and stages[1] == 2 and stages[2] == 5, "Expected list_stages to return unique stages [0, 2, 5] in sorted order")


func test_queue_dequeue_for_stage() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg_s0: Message = Message.new("stage0")
    msg_s0.stage = 0

    var msg_s1: Message = Message.new("stage1")
    msg_s1.stage = 1

    var msg_s2: Message = Message.new("stage2")
    msg_s2.stage = 2

    queue.enqueue(msg_s0)
    queue.enqueue(msg_s1)
    queue.enqueue(msg_s2)

    var result: Message = queue.dequeue_for_stage(1)

    return assert_true(result != null and result.id == "stage1" and queue.size() == 2, "Expected dequeue_for_stage(1) to return stage1 message and reduce size to 2")


func test_queue_dequeue_for_stage_not_found() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg"))

    var result: Message = queue.dequeue_for_stage(5)

    return assert_true(result == null and queue.size() == 1, "Expected dequeue_for_stage with non-existent stage to return null and not affect size")


func test_queue_dequeue_for_stage_multiple_with_same_stage() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 1
    msg1.priority = 5

    var msg2: Message = Message.new("msg2")
    msg2.stage = 1
    msg2.priority = 10

    var msg3: Message = Message.new("msg3")
    msg3.stage = 1
    msg3.priority = 1

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    var first: Message = queue.dequeue_for_stage(1)
    var second: Message = queue.dequeue_for_stage(1)
    var third: Message = queue.dequeue_for_stage(1)

    return assert_true(first.id == "msg2" and second.id == "msg1" and third.id == "msg3", "Expected dequeue_for_stage to respect priority ordering within stage")


func test_queue_peek_stage() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg_s0: Message = Message.new("stage0")
    msg_s0.stage = 0

    var msg_s1: Message = Message.new("stage1")
    msg_s1.stage = 1

    queue.enqueue(msg_s0)
    queue.enqueue(msg_s1)

    var result: Message = queue.peek_stage(1)

    return assert_true(result != null and result.id == "stage1" and queue.size() == 2, "Expected peek_stage to return stage1 message without removing it")


func test_queue_peek_stage_not_found() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg"))

    var result: Message = queue.peek_stage(5)

    return assert_null(result, "Expected peek_stage with non-existent stage to return null")


# =============================================================================
# MessageQueue Deduplication Tests
# =============================================================================


func test_queue_deduplication_default_enabled() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = true

    var msg1: Message = Message.new("duplicate")
    var msg2: Message = Message.new("duplicate")

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    return assert_equal(1, queue.size(), "Expected duplicate messages to be deduplicated (queue deduplicate=true, message policy=DEFAULT)")


func test_queue_deduplication_default_disabled() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("duplicate")
    var msg2: Message = Message.new("duplicate")

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    return assert_equal(2, queue.size(), "Expected duplicate messages to NOT be deduplicated (queue deduplicate=false, message policy=DEFAULT)")


func test_queue_deduplication_always() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false  # Queue deduplication is off

    var msg1: Message = Message.new("always_dedup")
    msg1.deduplicate = Message.DuplicatePolicy.ALWAYS

    var msg2: Message = Message.new("always_dedup")
    msg2.deduplicate = Message.DuplicatePolicy.ALWAYS

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    return assert_equal(1, queue.size(), "Expected ALWAYS policy to deduplicate even when queue deduplicate=false")


func test_queue_deduplication_never() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = true  # Queue deduplication is on

    var msg1: Message = Message.new("never_dedup")
    msg1.deduplicate = Message.DuplicatePolicy.NEVER

    var msg2: Message = Message.new("never_dedup")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    return assert_equal(2, queue.size(), "Expected NEVER policy to allow duplicates even when queue deduplicate=true")


func test_queue_deduplication_mixed_policies() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = true

    var msg1: Message = Message.new("msg1")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg2: Message = Message.new("msg1")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    return assert_equal(2, queue.size(), "Expected mixed policies: first DEFAULT (kept), second NEVER (allowed)")


func test_queue_deduplication_changing_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("msg1")
    var msg2: Message = Message.new("msg1")
    var msg3: Message = Message.new("msg2")

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    # Now enable deduplication - should remove duplicates with DEFAULT policy
    queue.deduplicate = true

    return assert_equal(2, queue.size(), "Expected enabling deduplicate to remove existing duplicates with DEFAULT policy")


func test_queue_deduplication_only_affects_default_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("never1")
    msg1.deduplicate = Message.DuplicatePolicy.NEVER

    var msg2: Message = Message.new("never1")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    var msg3: Message = Message.new("default1")
    msg3.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg4: Message = Message.new("default1")
    msg4.deduplicate = Message.DuplicatePolicy.DEFAULT

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)

    # Enabling deduplicate should only affect DEFAULT policy messages
    queue.deduplicate = true

    return assert_equal(3, queue.size())


func test_queue_deduplication_preserves_first_occurrence() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = true

    var msg1: Message = Message.new("msg")
    msg1.payload = "first"

    var msg2: Message = Message.new("msg")
    msg2.payload = "second"

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    var result: Message = queue.dequeue()

    return assert_equal("first", result.payload, "Expected deduplication to preserve the first occurrence")


# =============================================================================
# MessageQueue Edge Cases and Integration Tests
# =============================================================================


func test_queue_complex_scenario() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = true

    # Add messages across multiple stages and priorities
    var msg1: Message = Message.new("combat_attack")
    msg1.stage = 0
    msg1.priority = 10
    msg1.payload = {"damage": 50}

    var msg2: Message = Message.new("ui_update")
    msg2.stage = 1
    msg2.priority = 5

    var msg3: Message = Message.new("combat_attack")  # Duplicate
    msg3.stage = 0
    msg3.priority = 5

    var msg4: Message = Message.new("sound_effect")
    msg4.stage = 0
    msg4.priority = 1
    msg4.deduplicate = Message.DuplicatePolicy.NEVER

    var msg5: Message = Message.new("sound_effect")  # Same id but NEVER policy
    msg5.stage = 0
    msg5.priority = 1
    msg5.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)
    queue.enqueue(msg5)

    # Expected: combat_attack (deduplicated), ui_update, sound_effect x2 (NEVER policy)
    # Order: stage 0 messages first (combat_attack p10, sound_effect p1, sound_effect p1), then stage 1 (ui_update p5)

    var size_check: bool = queue.size() == 4
    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()
    var fourth: Message = queue.dequeue()

    return assert_true(
        size_check and first.id == "combat_attack" and second.id == "sound_effect" and third.id == "sound_effect" and fourth.id == "ui_update",
        "Expected complex scenario to handle stages, priorities, and deduplication correctly"
    )


func test_queue_empty_after_dequeue_all() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.dequeue()
    queue.dequeue()

    return assert_true(queue.is_empty() and queue.size() == 0 and queue.dequeue() == null, "Expected queue to be empty after dequeuing all messages")


func test_queue_has_message_after_dequeue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.dequeue()

    return assert_true(not queue.has_message("msg1") and queue.has_message("msg2"), "Expected has_message to reflect dequeued message removal")


func test_queue_peek_after_dequeue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.dequeue()
    var peeked: Message = queue.peek()

    return assert_equal("msg2", peeked.id, "Expected peek to return next message after dequeue")


func test_queue_stages_after_dequeue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 1

    var msg2: Message = Message.new("msg2")
    msg2.stage = 2

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    queue.dequeue_for_stage(1)
    var stages: Array[int] = queue.list_stages()

    return assert_true(stages.size() == 1 and stages[0] == 2, "Expected list_stages to update after dequeue_for_stage")


# =============================================================================
# MessageQueue Removal Functions Tests
# =============================================================================


func test_remove_stage_empty_queue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.remove_messages_in_stage(0)
    return assert_true(queue.is_empty(), "Expected remove_stage on empty queue to have no effect")


func test_remove_stage_single_stage() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 1

    var msg2: Message = Message.new("msg2")
    msg2.stage = 1

    var msg3: Message = Message.new("msg3")
    msg3.stage = 1

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_messages_in_stage(1)

    return assert_true(queue.is_empty(), "Expected remove_stage to remove all messages with stage 1")


func test_remove_stage_multiple_stages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 0

    var msg2: Message = Message.new("msg2")
    msg2.stage = 1

    var msg3: Message = Message.new("msg3")
    msg3.stage = 2

    var msg4: Message = Message.new("msg4")
    msg4.stage = 1

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)

    queue.remove_messages_in_stage(1)

    return assert_true(
        queue.size() == 2 and queue.has_message("msg1") and queue.has_message("msg3") and not queue.has_message("msg2") and not queue.has_message("msg4"),
        "Expected remove_stage to remove only messages with stage 1"
    )


func test_remove_stage_nonexistent() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.remove_messages_in_stage(99)

    return assert_equal(2, queue.size(), "Expected remove_stage with nonexistent stage to not affect queue")


func test_remove_stage_preserves_order() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var msg1: Message = Message.new("msg1")
    msg1.stage = 0
    msg1.priority = 10

    var msg2: Message = Message.new("msg2")
    msg2.stage = 1

    var msg3: Message = Message.new("msg3")
    msg3.stage = 0
    msg3.priority = 5

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_messages_in_stage(1)

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()

    return assert_true(first.id == "msg1" and second.id == "msg3", "Expected remove_stage to preserve ordering of remaining messages")


func test_remove_messages_with_id_empty_queue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.remove_messages_with_id("test")
    return assert_true(queue.is_empty(), "Expected remove_messages_with_id on empty queue to have no effect")


func test_remove_messages_with_id_single_occurrence() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("target"))
    queue.enqueue(Message.new("msg2"))

    queue.remove_messages_with_id("target")

    return assert_true(
        queue.size() == 2 and not queue.has_message("target") and queue.has_message("msg1") and queue.has_message("msg2"),
        "Expected remove_messages_with_id to remove the target message"
    )


func test_remove_messages_with_id_multiple_occurrences() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("target")
    msg1.deduplicate = Message.DuplicatePolicy.NEVER

    var msg2: Message = Message.new("other")

    var msg3: Message = Message.new("target")
    msg3.deduplicate = Message.DuplicatePolicy.NEVER

    var msg4: Message = Message.new("target")
    msg4.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)

    queue.remove_messages_with_id("target")

    return assert_true(
        queue.size() == 1 and not queue.has_message("target") and queue.has_message("other"), "Expected remove_messages_with_id to remove all messages with target id"
    )


func test_remove_messages_with_id_nonexistent() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.remove_messages_with_id("nonexistent")

    return assert_equal(2, queue.size(), "Expected remove_messages_with_id with nonexistent id to not affect queue")


func test_remove_messages_with_id_different_stages_priorities() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("target")
    msg1.stage = 0
    msg1.priority = 10
    msg1.deduplicate = Message.DuplicatePolicy.NEVER

    var msg2: Message = Message.new("keep")
    msg2.stage = 1

    var msg3: Message = Message.new("target")
    msg3.stage = 2
    msg3.priority = 5
    msg3.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_messages_with_id("target")

    return assert_true(
        queue.size() == 1 and queue.has_message("keep") and not queue.has_message("target"),
        "Expected remove_messages_with_id to remove all occurrences regardless of stage/priority"
    )


func test_remove_duplicates_no_duplicates() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))
    queue.enqueue(Message.new("msg3"))

    queue.remove_duplicates()

    return assert_equal(3, queue.size(), "Expected remove_duplicates with no duplicates to keep all messages")


func test_remove_duplicates_with_default_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("duplicate")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT
    msg1.payload = "first"

    var msg2: Message = Message.new("duplicate")
    msg2.deduplicate = Message.DuplicatePolicy.DEFAULT
    msg2.payload = "second"

    var msg3: Message = Message.new("duplicate")
    msg3.deduplicate = Message.DuplicatePolicy.DEFAULT
    msg3.payload = "third"

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_duplicates()

    var remaining: Message = queue.dequeue()

    return assert_true(
        queue.size() == 0 and remaining != null and remaining.id == "duplicate" and remaining.payload == "third",
        "Expected remove_duplicates to keep last occurrence of DEFAULT policy duplicates"
    )


func test_remove_duplicates_respects_never_policy_false() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("identical_id")
    msg1.deduplicate = Message.DuplicatePolicy.NEVER

    var msg2: Message = Message.new("identical_id")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    queue.enqueue(msg1)
    queue.enqueue(msg2)

    queue.remove_duplicates(false)

    return assert_equal(1, queue.size())


func test_remove_duplicates_respects_never_policy_true() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("identical_id")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg2: Message = Message.new("identical_id")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    var msg3: Message = Message.new("identical_id")
    msg3.deduplicate = Message.DuplicatePolicy.DEFAULT

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_duplicates(true)

    if queue.size() != 1:
        return fail_test("Expected queue to be of size 1, got " + str(queue.size()))

    if not queue.has_message("identical_id"):
        return fail_test("Expected queue to have message with id 'identical_id', got " + str(queue.peek().id))

    if queue.peek().deduplicate != Message.DuplicatePolicy.NEVER:
        return fail_test("Expected peek to return message with deduplicate policy NEVER, got " + str(queue.peek().deduplicate))

    return pass_test()


func test_remove_duplicates_mixed_policies() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("dup1")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg2: Message = Message.new("dup1")
    msg2.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg3: Message = Message.new("dup2")
    msg3.deduplicate = Message.DuplicatePolicy.NEVER

    var msg4: Message = Message.new("dup2")
    msg4.deduplicate = Message.DuplicatePolicy.NEVER

    var msg5: Message = Message.new("unique")

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)
    queue.enqueue(msg5)

    queue.remove_duplicates(false)

    return assert_true(
        queue.size() == 3 and queue.has_message("dup1") and queue.has_message("dup2") and queue.has_message("unique"),
        "Expected remove_duplicates to handle mixed policies correctly"
    )


func test_remove_duplicates_preserves_order() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("unique1")
    msg1.priority = 10

    var msg2: Message = Message.new("dup")
    msg2.priority = 5

    var msg3: Message = Message.new("dup")
    msg3.priority = 5

    var msg4: Message = Message.new("unique2")
    msg4.priority = 1

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)
    queue.enqueue(msg4)

    queue.remove_duplicates()

    var first: Message = queue.dequeue()
    var second: Message = queue.dequeue()
    var third: Message = queue.dequeue()

    return assert_true(first.id == "unique1" and second.id == "dup" and third.id == "unique2", "Expected remove_duplicates to preserve message ordering")


func test_remove_duplicates_with_id_no_matching_id() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.remove_duplicates_with_id("nonexistent")

    return assert_equal(2, queue.size(), "Expected remove_duplicates_with_id with nonexistent id to not affect queue")


func test_remove_duplicates_with_id_removes_all_default_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("target")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg2: Message = Message.new("other")

    var msg3: Message = Message.new("target")
    msg3.deduplicate = Message.DuplicatePolicy.DEFAULT

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_duplicates_with_id("target")

    return assert_equal(2, queue.size())


func test_remove_duplicates_with_id_preserves_never_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("target")
    msg1.deduplicate = Message.DuplicatePolicy.DEFAULT

    var msg2: Message = Message.new("target")
    msg2.deduplicate = Message.DuplicatePolicy.NEVER

    var msg3: Message = Message.new("target")
    msg3.deduplicate = Message.DuplicatePolicy.DEFAULT

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_duplicates_with_id("target", true)

    if queue.size() != 1:
        return fail_test("Expected queue to be of size 1, got " + str(queue.size()))

    if not queue.has_message("target"):
        return fail_test("Expected queue to have message with id 'target', got " + str(queue.peek().id))

    if queue.peek().deduplicate != Message.DuplicatePolicy.NEVER:
        return fail_test("Expected peek to return message with deduplicate policy NEVER, got " + str(queue.peek().deduplicate))

    return pass_test()


func test_remove_duplicates_with_id_preserves_always_policy() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false

    var msg1: Message = Message.new("target")
    msg1.deduplicate = Message.DuplicatePolicy.ALWAYS

    var msg2: Message = Message.new("target")
    msg2.deduplicate = Message.DuplicatePolicy.ALWAYS

    var msg3: Message = Message.new("target")
    msg3.deduplicate = Message.DuplicatePolicy.ALWAYS

    queue.enqueue(msg1)
    queue.enqueue(msg2)
    queue.enqueue(msg3)

    queue.remove_duplicates_with_id("target")

    return assert_true(
        queue.size() == 1 and queue.has_message("target") and queue.peek().deduplicate == Message.DuplicatePolicy.ALWAYS,
        "Expected remove_duplicates_with_id to preserve ALWAYS policy messages"
    )


func test_remove_duplicates_with_id_empty_queue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.remove_duplicates_with_id("test")
    return assert_true(queue.is_empty(), "Expected remove_duplicates_with_id on empty queue to have no effect")


# =============================================================================
# MessageQueue Delayed Enqueue Tests
# =============================================================================


func test_enqueue_after_ms_not_immediate() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_msg")

    queue.enqueue_after_ms(message, 1000)

    return assert_true(queue.is_empty() and not queue.has_message("delayed_msg"), "Expected message enqueued with delay to not appear immediately in queue")


func test_enqueue_after_ms_sets_timestamp() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_msg")
    var before_time: int = Time.get_ticks_msec()

    queue.enqueue_after_ms(message, 500)

    return assert_true(
        message.internal_enqueue_after_timestamp > before_time and message.internal_enqueue_after_timestamp <= before_time + 500 + 10,
        "Expected internal timestamp to be set correctly (within margin)"
    )


func test_enqueue_after_ms_zero_delay() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("immediate_msg")

    queue.enqueue_after_ms(message, 0)

    # With 0 delay, it should still be delayed (not immediately enqueued)
    # but should be enqueued on the very next process frame
    return assert_false(queue.has_message("immediate_msg"), "Expected 0ms delay to still defer to next frame")


func test_enqueue_after_ms_multiple_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var msg1: Message = Message.new("delayed1")
    var msg2: Message = Message.new("delayed2")
    var msg3: Message = Message.new("delayed3")

    queue.enqueue_after_ms(msg1, 100)
    queue.enqueue_after_ms(msg2, 200)
    queue.enqueue_after_ms(msg3, 300)

    return assert_true(queue.is_empty() and queue.size() == 0, "Expected all delayed messages to not be in main queue yet")


func test_enqueue_after_ms_mixed_with_normal() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal1"))
    queue.enqueue_after_ms(Message.new("delayed1"), 100)
    queue.enqueue(Message.new("normal2"))

    return assert_true(
        queue.size() == 2 and queue.has_message("normal1") and queue.has_message("normal2") and not queue.has_message("delayed1"),
        "Expected normal messages to be in queue, delayed messages not"
    )


func test_enqueue_after_frames_not_immediate() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_frame_msg")

    queue.enqueue_after_frames(message, 10)

    return assert_true(queue.is_empty() and not queue.has_message("delayed_frame_msg"), "Expected message enqueued with frame delay to not appear immediately in queue")


func test_enqueue_after_frames_sets_frame_stamp() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_frame_msg")
    var current_frame: int = Engine.get_process_frames()

    queue.enqueue_after_frames(message, 5)

    return assert_equal(current_frame + 5, message.internal_enqueue_after_frame_stamp, "Expected internal frame stamp to be set correctly")


func test_enqueue_after_frames_zero_delay() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("immediate_frame_msg")

    queue.enqueue_after_frames(message, 0)

    # With 0 frame delay, it should still be delayed to next frame
    return assert_false(queue.has_message("immediate_frame_msg"), "Expected 0 frame delay to still defer to next frame")


func test_enqueue_after_frames_multiple_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var msg1: Message = Message.new("frame_delayed1")
    var msg2: Message = Message.new("frame_delayed2")
    var msg3: Message = Message.new("frame_delayed3")

    queue.enqueue_after_frames(msg1, 1)
    queue.enqueue_after_frames(msg2, 2)
    queue.enqueue_after_frames(msg3, 3)

    return assert_true(queue.is_empty() and queue.size() == 0, "Expected all frame-delayed messages to not be in main queue yet")


func test_enqueue_after_frames_mixed_with_normal() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal1"))
    queue.enqueue_after_frames(Message.new("frame_delayed1"), 5)
    queue.enqueue(Message.new("normal2"))

    return assert_true(
        queue.size() == 2 and queue.has_message("normal1") and queue.has_message("normal2") and not queue.has_message("frame_delayed1"),
        "Expected normal messages to be in queue, frame-delayed messages not"
    )


func test_delayed_messages_preserve_properties() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var message: Message = Message.new("delayed_with_props")
    message.priority = 10
    message.stage = 2
    message.payload = {"data": "test"}
    message.deduplicate = Message.DuplicatePolicy.ALWAYS

    queue.enqueue_after_ms(message, 100)

    return assert_true(
        message.priority == 10 and message.stage == 2 and message.payload == {"data": "test"} and message.deduplicate == Message.DuplicatePolicy.ALWAYS,
        "Expected delayed message to preserve all its properties"
    )


func test_delayed_enqueue_respects_priority_when_added() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    # Add a normal low priority message
    var low_priority: Message = Message.new("low")
    low_priority.priority = 1
    queue.enqueue(low_priority)

    # Create a high priority delayed message
    var high_priority: Message = Message.new("high")
    high_priority.priority = 10

    # Store the delay info before manual simulation
    queue.enqueue_after_ms(high_priority, 50)

    # Manually enqueue it to simulate the delay passing
    # (since we can't easily advance time in tests)
    queue.enqueue(high_priority)

    var first: Message = queue.dequeue()

    return assert_equal("high", first.id, "Expected delayed high priority message to be dequeued first when it gets enqueued")


func test_delayed_message_can_be_cancelled() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("cancellable")

    queue.enqueue_after_ms(message, 100)

    # Clear the queue (this should not affect delayed messages)
    queue.clear()

    # The delayed message should still not be in the main queue
    return assert_false(queue.has_message("cancellable"), "Expected delayed message to not be affected by queue.clear()")


func test_enqueue_after_ms_with_negative_delay() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("negative_delay")

    queue.enqueue_after_ms(message, -100)

    # Negative delay should still defer the message (treated as past timestamp)
    # The message won't be in the queue immediately
    return assert_false(queue.has_message("negative_delay"), "Expected negative delay to still defer message")


func test_enqueue_after_frames_with_negative_delay() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("negative_frame_delay")

    queue.enqueue_after_frames(message, -5)

    # Negative frame delay should still defer the message
    return assert_false(queue.has_message("negative_frame_delay"), "Expected negative frame delay to still defer message")


func test_enqueue_after_ms_zero_delay_added_on_next_frame() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_msg")

    queue.enqueue_after_ms(message, 0)

    await Engine.get_main_loop().process_frame

    if queue.size() != 1:
        return fail_test("Expected queue to be of size 1, got " + str(queue.size()))

    return assert_true(queue.has_message("delayed_msg"))


func test_enqueue_after_ms_in_queue_after_time() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_msg")

    queue.enqueue_after_ms(message, 90)

    if queue.size() != 0:
        return fail_test("Expected queue to be empty, got " + str(queue.size()))

    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 90:
        await Engine.get_main_loop().process_frame

    if queue.size() != 1:
        return fail_test("Expected queue to be of size 1, got " + str(queue.size()))

    return assert_true(queue.has_message("delayed_msg"))


func test_enqueue_after_frames_zero_delay_added_on_next_frame() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    var message: Message = Message.new("delayed_frame_msg")

    queue.enqueue_after_frames(message, 0)

    if queue.size() != 0:
        return fail_test("Expected queue to be empty, got " + str(queue.size()))

    await Engine.get_main_loop().process_frame

    return assert_equal(1, queue.size())


func test_enqueue_after_multiple_mixed_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    # Direct enqueues
    var direct_msg1: Message = Message.new("direct1")
    var direct_msg2: Message = Message.new("direct2")

    # Time-delayed messages
    var time_msg1: Message = Message.new("time_delayed1")
    var time_msg2: Message = Message.new("time_delayed2")

    # Frame-delayed messages
    var frame_msg1: Message = Message.new("frame_delayed1")
    var frame_msg2: Message = Message.new("frame_delayed2")

    # Enqueue mixed types
    queue.enqueue(direct_msg1)
    queue.enqueue_after_ms(time_msg1, 50)
    queue.enqueue_after_frames(frame_msg1, 1)
    queue.enqueue(direct_msg2)
    queue.enqueue_after_ms(time_msg2, 120)
    queue.enqueue_after_frames(frame_msg2, 5)

    # Check initial state
    if queue.size() != 2:
        return fail_test("Expected 2 direct messages in queue, got " + str(queue.size()))

    if not queue.has_message("direct1") or not queue.has_message("direct2"):
        return fail_test("Expected direct messages to be in queue")

    # Wait for frame-delayed messages
    for i in range(2):  # Wait 1 extra to avoid order of execution issues
        await Engine.get_main_loop().process_frame

    if queue.size() != 3:
        return fail_test("Expected 3 messages after first frame (2 direct + 1 frame), got " + str(queue.size()))

    if not queue.has_message("frame_delayed1"):
        return fail_test("Expected frame_delayed1 to be enqueued after first frame")

    for i in range(4):  # Wait 1 extra to avoid order of execution issues
        await Engine.get_main_loop().process_frame

    if queue.size() != 4:
        return fail_test("Expected 4 messages after second frame (2 direct + 2 frame), got " + str(queue.size()))

    if not queue.has_message("frame_delayed2"):
        return fail_test("Expected frame_delayed2 to be enqueued after second frame")

    # Wait for time-delayed messages
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 110:
        await Engine.get_main_loop().process_frame

    if queue.size() != 6:
        return fail_test("Expected 6 messages after time delays (2 direct + 2 frame + 2 time), got " + str(queue.size()))

    if not queue.has_message("time_delayed1") or not queue.has_message("time_delayed2"):
        return fail_test("Expected both time-delayed messages to be enqueued")

    return assert_true(
        (
            queue.has_message("direct1")
            and queue.has_message("direct2")
            and queue.has_message("frame_delayed1")
            and queue.has_message("frame_delayed2")
            and queue.has_message("time_delayed1")
            and queue.has_message("time_delayed2")
        ),
        "Expected all mixed message types to be properly enqueued in correct order"
    )


# =============================================================================
# Clear and Remove Functions for Delayed Messages Tests
# =============================================================================


func test_clear_only_main_queue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal1"))
    queue.enqueue(Message.new("normal2"))
    queue.enqueue_after_ms(Message.new("delayed1"), 100)
    queue.enqueue_after_ms(Message.new("delayed2"), 200)

    queue.clear()

    return assert_true(queue.is_empty(), "Expected main queue to be empty after clear()")


func test_clear_including_delayed_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal1"))
    queue.enqueue(Message.new("normal2"))
    queue.enqueue_after_ms(Message.new("delayed1"), 100)
    queue.enqueue_after_ms(Message.new("delayed2"), 200)

    queue.clear()
    queue.clear_delayed_messages()

    # After clear with delayed messages, wait a frame to verify nothing gets enqueued
    await Engine.get_main_loop().process_frame

    return assert_true(queue.is_empty(), "Expected both main and delayed queues to be cleared")


func test_clear_default_clears_delayed_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal"))
    queue.enqueue_after_ms(Message.new("delayed"), 100)

    queue.clear()  # Default should clear delayed messages too

    await Engine.get_main_loop().process_frame

    return assert_true(queue.is_empty(), "Expected clear() to clear delayed messages by default")


func test_clear_delayed_messages_only() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal1"))
    queue.enqueue(Message.new("normal2"))
    queue.enqueue_after_ms(Message.new("delayed1"), 100)
    queue.enqueue_after_ms(Message.new("delayed2"), 200)

    queue.clear_delayed_messages()

    return assert_true(queue.size() == 2 and queue.has_message("normal1") and queue.has_message("normal2"), "Expected main queue to remain intact after clearing delayed messages")


func test_clear_delayed_messages_prevents_future_enqueue() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue_after_ms(Message.new("delayed1"), 50)
    queue.enqueue_after_ms(Message.new("delayed2"), 100)

    queue.clear_delayed_messages()

    # Wait for the delay to pass
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_true(queue.is_empty(), "Expected delayed messages to not be enqueued after being cleared")


func test_remove_messages_in_stage_does_not_affect_delayed() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var normal_msg: Message = Message.new("normal_stage1")
    normal_msg.stage = 1

    var delayed_msg: Message = Message.new("delayed_stage1")
    delayed_msg.stage = 1

    queue.enqueue(normal_msg)
    queue.enqueue_after_ms(delayed_msg, 100)

    queue.remove_messages_in_stage(1)

    return assert_true(queue.is_empty(), "Expected normal message with stage 1 to be removed")


func test_remove_delayed_messages_in_stage_does_not_affect_main() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var normal_msg: Message = Message.new("normal_stage1")
    normal_msg.stage = 1

    var delayed_msg: Message = Message.new("delayed_stage1")
    delayed_msg.stage = 1

    queue.enqueue(normal_msg)
    queue.enqueue_after_ms(delayed_msg, 100)

    queue.remove_delayed_messages_in_stage(1)

    # Verify main queue still has the message
    if queue.size() != 1:
        return fail_test("Expected main queue to still have 1 message, got " + str(queue.size()))

    # Wait for delay to pass and verify delayed message wasn't enqueued
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_equal(1, queue.size(), "Expected delayed message to not be enqueued after being removed")


func test_remove_delayed_messages_in_stage_multiple_stages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var delayed1: Message = Message.new("delayed_stage0")
    delayed1.stage = 0

    var delayed2: Message = Message.new("delayed_stage1")
    delayed2.stage = 1

    var delayed3: Message = Message.new("delayed_stage2")
    delayed3.stage = 2

    queue.enqueue_after_ms(delayed1, 100)
    queue.enqueue_after_ms(delayed2, 100)
    queue.enqueue_after_ms(delayed3, 100)

    queue.remove_delayed_messages_in_stage(1)

    # Wait for delay
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_true(
        queue.size() == 2 and queue.has_message("delayed_stage0") and queue.has_message("delayed_stage2") and not queue.has_message("delayed_stage1"),
        "Expected only stage 1 delayed message to be removed"
    )


func test_remove_messages_with_id_does_not_affect_delayed() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("target_id"))
    queue.enqueue_after_ms(Message.new("target_id"), 100)

    queue.remove_messages_with_id("target_id")

    # Main queue should be empty
    if not queue.is_empty():
        return fail_test("Expected main queue to be empty after removing messages with target_id")

    # Wait for delay to verify the delayed message still gets enqueued
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_true(queue.size() == 1 and queue.has_message("target_id"), "Expected delayed message with same id to still be enqueued")


func test_remove_delayed_messages_with_id_does_not_affect_main() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("target_id"))
    queue.enqueue_after_ms(Message.new("target_id"), 100)

    queue.remove_delayed_messages_with_id("target_id")

    # Main queue should still have the message
    if queue.size() != 1:
        return fail_test("Expected main queue to still have 1 message, got " + str(queue.size()))

    # Wait for delay to verify the delayed message doesn't get enqueued
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_equal(1, queue.size(), "Expected delayed message to not be enqueued after being removed")


func test_remove_delayed_messages_with_id_multiple_ids() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue_after_ms(Message.new("id1"), 100)
    queue.enqueue_after_ms(Message.new("id2"), 100)
    queue.enqueue_after_ms(Message.new("id3"), 100)
    queue.enqueue_after_ms(Message.new("id2"), 100)  # Duplicate

    queue.remove_delayed_messages_with_id("id2")

    # Wait for delay
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_true(
        queue.size() == 2 and queue.has_message("id1") and queue.has_message("id3") and not queue.has_message("id2"), "Expected all delayed messages with id2 to be removed"
    )


func test_clear_mixed_queue_with_both_delayed_and_normal() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    # Add normal messages
    queue.enqueue(Message.new("normal1"))
    queue.enqueue(Message.new("normal2"))
    queue.enqueue(Message.new("normal3"))

    # Add delayed messages
    queue.enqueue_after_ms(Message.new("delayed1"), 100)
    queue.enqueue_after_frames(Message.new("delayed2"), 5)
    queue.enqueue_after_ms(Message.new("delayed3"), 200)

    # Verify initial state
    if queue.size() != 3:
        return fail_test("Expected 3 normal messages in queue, got " + str(queue.size()))

    # Clear without affecting delayed
    queue.clear()

    if not queue.is_empty():
        return fail_test("Expected main queue to be empty after clear()")

    # Wait for some delayed messages to be enqueued
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    # Some delayed messages should have been enqueued
    return assert_greater_than(queue.size(), 0, "Expected delayed messages to be enqueued after clear(false)")


func test_remove_stage_and_delayed_stage_independently() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    # Stage 0 messages
    var normal_s0: Message = Message.new("normal_s0")
    normal_s0.stage = 0
    var delayed_s0: Message = Message.new("delayed_s0")
    delayed_s0.stage = 0

    # Stage 1 messages
    var normal_s1: Message = Message.new("normal_s1")
    normal_s1.stage = 1
    var delayed_s1: Message = Message.new("delayed_s1")
    delayed_s1.stage = 1

    queue.enqueue(normal_s0)
    queue.enqueue(normal_s1)
    queue.enqueue_after_ms(delayed_s0, 100)
    queue.enqueue_after_ms(delayed_s1, 100)

    # Remove stage 0 from both queues
    queue.remove_messages_in_stage(0)
    queue.remove_delayed_messages_in_stage(0)

    # Main queue should only have stage 1
    if queue.size() != 1 or not queue.has_message("normal_s1"):
        return fail_test("Expected only normal_s1 to remain in main queue")

    # Wait for delayed messages
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    # Only delayed_s1 should have been enqueued
    return assert_true(
        queue.size() == 2 and queue.has_message("normal_s1") and queue.has_message("delayed_s1") and not queue.has_message("delayed_s0"), "Expected only stage 1 messages to remain"
    )


func test_remove_id_and_delayed_id_independently() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.deduplicate = false  # Make sure deduplication doesn't mess up the test

    queue.enqueue(Message.new("enqueued_keep_me"))
    queue.enqueue(Message.new("remove_me"))
    queue.enqueue(Message.new("enqueued_keep_me"))
    queue.enqueue_after_ms(Message.new("delayed_ms_keep_me"), 100)
    queue.enqueue_after_ms(Message.new("remove_me"), 100)
    queue.enqueue_after_frames(Message.new("delayed_frames_keep_me"), 2)
    queue.enqueue_after_frames(Message.new("remove_me"), 3)

    # Verify initial state
    if queue.size() != 3:
        return fail_test("Expected 3 messages in queue, got " + str(queue.size()))

    if queue._delayed_messages.size() != 4:
        return fail_test("Expected 4 messages in delayed queue, got " + str(queue._delayed_messages.size()))

    # Remove "remove_me" from the actual queue
    queue.remove_messages_with_id("remove_me")

    # Verify delayed queue unaffected
    if queue._delayed_messages.size() != 4:
        return fail_test("Expected 4 messages in delayed queue, got " + str(queue._delayed_messages.size()))

    # Add it back, then remove from the _delayed_ queue
    queue.enqueue(Message.new("remove_me"))
    queue.remove_delayed_messages_with_id("remove_me")

    if not queue.has_message("remove_me"):
        return fail_test("Expected remove_me to be in main queue")

    # Verify delayed queue had the message removed
    if queue.has_delayed_message("remove_me"):
        return fail_test("Expected remove_me to be removed from delayed queue")

    # Verify delayed queue has the remaining messages
    if queue._delayed_messages.size() != 2:
        return fail_test("Expected 2 messages in delayed queue, got " + str(queue._delayed_messages.size()))

    # Wait 100ms + 3 frames to make sure the delayed messages are enqueued
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 100:
        await Engine.get_main_loop().process_frame
    for i in range(3):
        await Engine.get_main_loop().process_frame

    # Verify delayed queue now empty
    if queue._delayed_messages.size() != 0:
        return fail_test("Expected delayed queue to be empty, got " + str(queue._delayed_messages.size()))

    # Verify main queue has all remaining messages (including the one that was added back)
    if queue.size() != 5:
        return fail_test("Expected 5 messages in main queue, got " + str(queue.size()))

    return assert_true(
        queue.has_message("enqueued_keep_me") and queue.has_message("delayed_ms_keep_me") and queue.has_message("delayed_frames_keep_me"),
        "Expected all correct messages to remain and none of the ones to be removed"
    )


func test_clear_empty_delayed_messages() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue(Message.new("normal"))
    queue.clear_delayed_messages()

    return assert_equal(1, queue.size(), "Expected clearing empty delayed queue to not affect main queue")


func test_remove_delayed_messages_nonexistent_stage() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    var delayed: Message = Message.new("delayed")
    delayed.stage = 1

    queue.enqueue_after_ms(delayed, 100)
    queue.remove_delayed_messages_in_stage(99)

    # Wait for delayed message
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_equal(1, queue.size(), "Expected delayed message to still be enqueued when removing nonexistent stage")


func test_remove_delayed_messages_nonexistent_id() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()

    queue.enqueue_after_ms(Message.new("delayed"), 100)
    queue.remove_delayed_messages_with_id("nonexistent")

    # Wait for delayed message
    var start_time: int = Time.get_ticks_msec()
    while Time.get_ticks_msec() - start_time < 150:
        await Engine.get_main_loop().process_frame

    return assert_equal(1, queue.size(), "Expected delayed message to still be enqueued when removing nonexistent id")
