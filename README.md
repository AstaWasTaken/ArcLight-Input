# ArcLight Input

> A lightweight, priority-based input management system for Roblox

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Wally](https://img.shields.io/badge/Wally-1.0.6-blue)](https://wally.run/package/nontkph/arclightinput)

## Features

- **Priority System** – Manage input conflicts with customizable priority levels
- **Input Buffering** – Capture inputs within configurable time windows
- **Combo Detection** – Detect sequences and combos with the built-in sequence system
- **Multi-Device Support** – Seamless support for keyboard, mouse, gamepad, and touch
- **UI Integration** – Built-in helpers for UI focus and modal states
- **Type-Safe** – Full Luau type definitions included

## Installation

### Via Wally (Recommended)

Add to your `wally.toml`:

```toml
[dependencies]
arclightinput = "nontkph/arclightinput@1"
```

Then run:

```bash
wally install
```

### Manual Installation

1. Download the latest release from [Releases](https://github.com/nontkph/ArcLight-Input/releases)
2. Place `Core/` and `init.luau` in your project
3. Require the module in your scripts

## Quick Start

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Arc = require(ReplicatedStorage.Packages.arclightinput)

-- Create an action registry
local Actions = Arc.ActionRegistry.new()

-- Register an action with priority
Actions:register("Jump", {
    priority = 10,
    keys = { Enum.KeyCode.Space },
    gamepad = { Enum.KeyCode.ButtonA }
})

-- Listen for input events
Actions:onBegan("Jump", function(context)
    print("Jump started!", context.device, context.timestamp)
end)

Actions:onEnded("Jump", function(context)
    print("Jump ended!")
end)
```

## Advanced Usage

### Input Buffering

Perfect for fighting games or precise input windows:

```lua
local Buffer = Arc.BufferSystem.new(0.2) -- 200ms window

-- Record inputs
Buffer:record("LightPunch")
Buffer:record("HeavyPunch")

-- Check for sequences
if Buffer:matches({"LightPunch", "HeavyPunch"}) then
    print("Combo executed!")
end
```

### Device Detection

```lua
local Detector = Arc.DeviceDetector.new()

Detector:onDeviceChanged(function(device)
    print("Switched to:", device) -- "Keyboard", "Gamepad", "Touch", etc.
end)

local currentDevice = Detector:getCurrentDevice()
```

### UI Integration

```lua
local UI = Arc.UIIntegration.new()

-- Block game inputs when UI is focused
UI:setUIFocused(true)

-- Check if inputs should be blocked
if UI:shouldBlockInputs() then
    -- Skip game input processing
end
```

## API Reference

### ActionRegistry

| Method | Description |
|--------|-------------|
| `new()` | Create a new action registry |
| `:register(name, config)` | Register a new action with keys and priority |
| `:onBegan(name, callback)` | Listen for action start |
| `:onEnded(name, callback)` | Listen for action end |
| `:unregister(name)` | Remove an action |

### BufferSystem

| Method | Description |
|--------|-------------|
| `new(windowSeconds)` | Create buffer with time window |
| `:record(actionName)` | Record an input to the buffer |
| `:matches(sequence)` | Check if buffer matches a sequence |
| `:clear()` | Clear the buffer |

### DeviceDetector

| Method | Description |
|--------|-------------|
| `new()` | Create device detector |
| `:getCurrentDevice()` | Get current input device |
| `:onDeviceChanged(callback)` | Listen for device switches |

## Project Structure

```
ArcLight-Input/
├── Core/
│   ├── ActionRegistry.luau    # Action management
│   ├── BufferSystem.luau      # Input buffering
│   ├── DeviceDetector.luau    # Device detection
│   ├── InputProcessor.luau    # Input normalization
│   ├── SequenceDetector.luau  # Combo/sequence detection
│   ├── Types.luau             # Type definitions
│   └── UIIntegration.luau     # UI helpers
├── init.luau                  # Entry point
├── wally.toml                 # Package manifest
└── README.md
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

Made with ❤️ for the Roblox community
