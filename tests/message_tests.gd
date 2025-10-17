extends GDTestCase


func test_message_creation_defaults() -> GDTestResult:
    var message: Message = Message.new("test_message")
    return assert_true(
        (
            message != null
            and message.id == "test_message"
            and message.payload == null
            and message.priority == 0
            and message.stage == 0
            and message.deduplicate == Message.DuplicatePolicy.DEFAULT
        ),
        "Expected message to have correct default properties"
    )


func test_message_creation_with_payload() -> GDTestResult:
    var test_payload: Dictionary = {"test_key": "test_value"}
    var message: Message = Message.new("test_message", test_payload)
    if (
        message == null
        or message.id != "test_message"
        or message.payload != test_payload
        or message.priority != 0
        or message.stage != 0
        or message.deduplicate != Message.DuplicatePolicy.DEFAULT
    ):
        return fail_test("Message creation failed")
    return assert_true(message.payload.has("test_key") and message.payload["test_key"] == "test_value", "Expected payload to have 'test_key' with value 'test_value'")


func test_message_creation_with_all_settings() -> GDTestResult:
    var test_payload: Dictionary = {"key": "value"}
    var message: Message = Message.new("test_message", test_payload)
    message.priority = 1
    message.stage = 2
    message.deduplicate = Message.DuplicatePolicy.ALWAYS
    return assert_true(
        (
            message != null
            and message.id == "test_message"
            and message.payload == test_payload
            and message.priority == 1
            and message.stage == 2
            and message.deduplicate == Message.DuplicatePolicy.ALWAYS
        ),
        "Expected message to have properties as they were set"
    )
