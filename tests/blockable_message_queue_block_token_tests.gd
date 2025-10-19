extends GDTestCase


func test_token_construction_defaults() -> GDTestResult:
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new()
    return assert_true(
        token != null and token.key == "" and token.timeout_timestamp == 0 and token.timeout_framestamp == 0, "Expected default construction to set empty key and no timeouts"
    )


func test_token_construction_with_all_params() -> GDTestResult:
    var now_ms: int = Time.get_ticks_msec()
    var now_frames: int = Engine.get_process_frames()

    var key := "k"
    var timeout_ms := 100
    var timeout_frames := 2
    var predicate := func() -> bool: return false

    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new(key, timeout_ms, timeout_frames, predicate)

    if token == null or token.key != key:
        return fail_test("Expected token to be constructed with provided key")

    # Tolerate some timing drift in construction
    var expected_ts: int = now_ms + timeout_ms
    var expected_fs: int = now_frames + timeout_frames

    var ts_ok: bool = abs(token.timeout_timestamp - expected_ts) <= 50
    var fs_ok: bool = token.timeout_framestamp == expected_fs

    return assert_true(ts_ok and fs_ok, "Expected timeout fields to be set from now + offsets")


func test_is_expired_predicate_true() -> GDTestResult:
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new("", 0, 0, func() -> bool: return true)
    return assert_true(token.is_expired())


func test_is_expired_timeout_ms_only() -> GDTestResult:
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new("", 100)
    await Engine.get_main_loop().create_timer(0.3).timeout
    return assert_true(token.is_expired())


func test_is_expired_timeout_frames_only() -> GDTestResult:
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new("", 0, 1)
    await Engine.get_main_loop().process_frame
    return assert_true(token.is_expired())


func test_is_expired_combined_predicate_false_but_timeout_ms_expired() -> GDTestResult:
    # Spec: first condition to pass should expire the token (OR semantics)
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new("", 0, 0, func() -> bool: return false)
    token.timeout_timestamp = Time.get_ticks_msec() - 1  # expired by time
    return assert_true(token.is_expired())


func test_is_expired_combined_none_expired() -> GDTestResult:
    var token: BlockableMessageQueueBlockToken = BlockableMessageQueueBlockToken.new("", 0, 0, func() -> bool: return false)
    token.timeout_timestamp = 0
    token.timeout_framestamp = 0
    return assert_false(token.is_expired())
