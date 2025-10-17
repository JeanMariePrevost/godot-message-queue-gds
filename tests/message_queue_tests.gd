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
    queue.remove_stage(0)
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

    queue.remove_stage(1)

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

    queue.remove_stage(1)

    return assert_true(
        queue.size() == 2 and queue.has_message("msg1") and queue.has_message("msg3") and not queue.has_message("msg2") and not queue.has_message("msg4"),
        "Expected remove_stage to remove only messages with stage 1"
    )


func test_remove_stage_nonexistent() -> GDTestResult:
    var queue: MessageQueue = MessageQueue.new()
    queue.enqueue(Message.new("msg1"))
    queue.enqueue(Message.new("msg2"))

    queue.remove_stage(99)

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

    queue.remove_stage(1)

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
