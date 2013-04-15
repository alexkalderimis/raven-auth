module.exports = class CallTracker

    called: false

    call: (...@args) -> @called = true
