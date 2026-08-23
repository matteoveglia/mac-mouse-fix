// Deterministic, dependency-free checks for ClickCycle's timer-generation semantics.

private enum ClickCycleTestPhase: Equatable {
    case press
    case hold
    case release
    case releaseFromHold
    case levelExpired
}

private enum ClickCycleTestButtonState: Equatable {
    case down
    case up
    case held
}

private struct ClickCycleTestState: Equatable {
    var device: Int
    var button: Int
    var generation: UInt64
    var pressState: ClickCycleTestButtonState
    var holdToken: UInt64?
    var expiryToken: UInt64?
}

private struct ClickCycleTestReducer {
    private(set) var state: ClickCycleTestState?
    private(set) var phases: [ClickCycleTestPhase] = []

    private var tokenCounter: UInt64 = 0

    mutating func press(device: Int, button: Int) -> (generation: UInt64, holdToken: UInt64, expiryToken: UInt64) {
        let clickGeneration = nextToken()
        let holdToken = nextToken()
        let expiryToken = nextToken()
        state = ClickCycleTestState(
            device: device,
            button: button,
            generation: clickGeneration,
            pressState: .down,
            holdToken: holdToken,
            expiryToken: expiryToken
        )
        phases.append(.press)
        return (clickGeneration, holdToken, expiryToken)
    }

    mutating func release(device: Int, button: Int) {
        guard var current = state, current.device == device, current.button == button else { return }
        if current.pressState == .held {
            phases.append(.releaseFromHold)
            kill()
            return
        }

        phases.append(.release)
        current.pressState = .up
        current.holdToken = nil
        state = current
    }

    mutating func kill() {
        guard state != nil else { return }
        state = nil
    }

    mutating func fireHold(device: Int, button: Int, generation: UInt64, token: UInt64) {
        guard var current = state,
              current.device == device,
              current.button == button,
              current.generation == generation,
              current.holdToken == token,
              current.pressState == .down
        else { return }

        phases.append(.hold)
        current.pressState = .held
        current.holdToken = nil
        current.expiryToken = nil
        state = current
    }

    mutating func fireExpiry(device: Int, button: Int, generation: UInt64, token: UInt64) {
        guard let current = state,
              current.device == device,
              current.button == button,
              current.generation == generation,
              current.expiryToken == token
        else { return }

        phases.append(.levelExpired)
        state = nil
    }

    private mutating func nextToken() -> UInt64 {
        tokenCounter &+= 1
        return tokenCounter
    }
}

public enum ClickCycleStateMachineTests {
    public static func run() {
        staleHoldAfterReleaseDoesNotFire()
        staleTimersAfterIdempotentKillDoNotFire()
        replacementGenerationRejectsOldTimers()
        validExpiryStillFiresAfterNormalRelease()
    }

    private static func staleHoldAfterReleaseDoesNotFire() {
        var reducer = ClickCycleTestReducer()
        let timer = reducer.press(device: 1, button: 6)
        reducer.release(device: 1, button: 6)
        reducer.fireHold(device: 1, button: 6, generation: timer.generation, token: timer.holdToken)
        check(reducer.phases == [.press, .release], "released hold timer must be stale")
    }

    private static func staleTimersAfterIdempotentKillDoNotFire() {
        var reducer = ClickCycleTestReducer()
        let timer = reducer.press(device: 1, button: 6)
        reducer.kill()
        reducer.kill()
        reducer.fireHold(device: 1, button: 6, generation: timer.generation, token: timer.holdToken)
        reducer.fireExpiry(device: 1, button: 6, generation: timer.generation, token: timer.expiryToken)
        check(reducer.phases == [.press], "killed timers must be stale and kill must be idempotent")
    }

    private static func replacementGenerationRejectsOldTimers() {
        var reducer = ClickCycleTestReducer()
        let oldTimer = reducer.press(device: 1, button: 6)
        reducer.kill()
        let newTimer = reducer.press(device: 1, button: 6)
        reducer.fireHold(device: 1, button: 6, generation: oldTimer.generation, token: oldTimer.holdToken)
        reducer.fireExpiry(device: 1, button: 6, generation: oldTimer.generation, token: oldTimer.expiryToken)
        reducer.fireHold(device: 1, button: 6, generation: newTimer.generation, token: newTimer.holdToken)
        check(reducer.phases == [.press, .press, .hold], "replacement cycle must reject old timer generations")
    }

    private static func validExpiryStillFiresAfterNormalRelease() {
        var reducer = ClickCycleTestReducer()
        let timer = reducer.press(device: 1, button: 6)
        reducer.release(device: 1, button: 6)
        reducer.fireExpiry(device: 1, button: 6, generation: timer.generation, token: timer.expiryToken)
        check(reducer.phases == [.press, .release, .levelExpired], "normal release must preserve level expiry")
        check(reducer.state == nil, "level expiry must end the cycle")
    }

    private static func check(_ condition: Bool, _ message: String) {
        precondition(condition, "ClickCycle state-machine test failed: \(message)")
    }
}

#if CLICK_CYCLE_STATE_MACHINE_TEST_MAIN
ClickCycleStateMachineTests.run()
print("ClickCycle state-machine tests passed")
#endif
