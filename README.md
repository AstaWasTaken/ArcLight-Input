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
local Input = require(ReplicatedStorage.Packages.arclightinput)

-- Register an action with priority 10
local Attack = Input.Register("Attack", 10)
    :Define(Enum.KeyCode.Q)

-- Listen for the input
Attack.OnBegan:Connect(function()
    player:Attack()
end)

Attack.OnEnded:Connect(function()
    player:StopAttack()
end)
```

That's it. Priority 10 blocks anything below it automatically.

## Common Patterns

### Enable Input Buffering

Queue inputs during animations:

```lua
Attack:EnableBuffer(0.3) -- 300ms window
```

Behavior:
- Press during a lock/animation → buffered.
- On key-up, the buffer auto re-fires once the action is unblocked/enabled (no extra calls).
- If you need manual control, call `Attack:ConsumeBuffer()` / `Attack:GetBufferedInput()`.

Real gameplay flow (auto replay):

```lua
local Attack = Input.Register("Attack", 10)
    :Define(Enum.KeyCode.Q)
    :EnableBuffer(0.35)

-- Enter an animation lock: disable to block immediate fire
Attack:Disable()
task.delay(0.2, function()
    Attack:Enable() -- when the player releases Q, the buffered press re-fires automatically
end)

Attack.OnBegan:Connect(function()
    player:Attack()
end)

Attack.OnEnded:Connect(function()
    player:StopAttack()
end)
```

Manual control example (only replay when you decide):

```lua
if Attack:ConsumeBuffer() then
    Attack.OnBegan:Fire() -- optional manual replay hook
end
```

### Multiple Input Types

```lua
local Attack = Input.Register("Attack", 10)
    :Define(Enum.KeyCode.Q)
    :Define(Enum.UserInputType.Touch)
```

Keyboard and touch both trigger the same action.

### Combo / Sequence Detection

```lua
local Ultimate = Input.Register("Ultimate", 9)
    :DefineSequence({
        Enum.KeyCode.Q,
        Enum.KeyCode.W,
        Enum.KeyCode.E
    }, 1.0) -- 1 second window to complete sequence

Ultimate.OnBegan:Connect(function()
    player:executeUltimate()
end)
```

Automatically detects the Q-W-E pattern within 1 second.

### UI Button Binding

```lua
local Shop = Input.Register("Shop", 8)
    :Define(Enum.KeyCode.B)
    :DefineUI(script.Parent.ShopButton)

Shop.OnBegan:Connect(function()
    toggleShop()
end)
```

One action handles both keyboard (B key) and the button. Same priority system applies.

### Runtime Remapping

```lua
-- In a keybind menu
local reader = Input.ReadInput("BindAttack", 1, 5)
reader:Connect(function(input)
    Attack:Remap(input.KeyCode)
    print("Attack rebound to", input.KeyCode)
end)
```

Captures the next keypress and rebinds automatically.

### Critical Priority (Always Works)

```lua
local Menu = Input.Register("Menu", Input.CRITICAL_PRIORITY)
    :Define(Enum.KeyCode.Escape)

Menu.OnBegan:Connect(function()
    openMenu()
end)
```

This action is never blocked, even when other inputs are disabled.

## API Reference

### Input (Main Module)

| Function | Description |
|----------|-------------|
| `Input.Register(name, priority)` | Register a new action, returns Action object |
| `Input.ReadInput(name, maxPresses, timeout)` | Capture next N keypresses within timeout (returns Signal) |
| `Input.GetDevice()` | Get current device type ("PC", "Mobile", "GamePad", "Console") |
| `Input.GetTelemetry()` | Get stats: totalInputs, droppedInputs, activeActions |
| `Input.CRITICAL_PRIORITY` | Constant for actions that cannot be blocked |

### Action (returned from Input.Register)

| Method | Returns | Description |
|--------|---------|-------------|
| `:Define(input)` | self | Add a keybind (Enum.KeyCode or Enum.UserInputType) |
| `:DefineSequence(inputs, window)` | self | Set up combo/sequence detection with time window |
| `:DefineUI(guiObject)` | self | Bind a UI button to this action |
| `:EnableBuffer(duration)` | self | Queue inputs for X seconds during locks |
| `:Undefine(input)` | self | Remove a keybind |
| `:UndefineUI()` | self | Remove UI binding |
| `:Remap(input)` | self | Change keybind at runtime |
| `:Enable()` | self | Re-enable the action |
| `:Disable()` | - | Disable the action temporarily |
| `:Destroy()` | - | Cleanup and remove the action |
| `.OnBegan` | Signal | Fires when input begins |
| `.OnEnded` | Signal | Fires when input ends |

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
