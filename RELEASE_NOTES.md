# ArcLight Input v1.0.6

**Production-ready input management for Roblox**

A stable, well-tested input system designed for action games where precise input handling, priority management, and combo detection matter.

## What's Included

- **Priority System** – Higher priority actions block lower ones automatically
- **Input Buffering** – Queue inputs during animations/cooldowns
- **Combo Detection** – Built-in sequence tracking with time windows
- **UI Integration** – Bind buttons to the same action system as keyboard
- **Device Detection** – Automatic device switching (Keyboard/Gamepad/Touch)
- **Runtime Remapping** – Change keybinds at runtime, no code changes needed
- **Critical Priority** – Actions that never get blocked
- **Cross-Platform** – Works on PC, mobile, and console without extra work

## Installation

### Wally (recommended)

```toml
[dependencies]
arclightinput = "nontkph/arclightinput@1"
```

Run `wally install`.

### Manual

Download from [Releases](https://github.com/nontkph/ArcLight-Input/releases), place `Core/` and `init.luau` in your project.

## Quick Example

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Input = require(ReplicatedStorage.Packages.arclightinput)

-- Register an action
local Attack = Input.Register("Attack", 10)
    :Define(Enum.KeyCode.Q)
    :EnableBuffer(0.3)

Attack.OnBegan:Connect(function()
    player:Attack()
end)
```

Priority 10 blocks anything below it. Buffering queues inputs during animations. That's it.

## Key Features in Action

### Combo Detection

```lua
local Ultimate = Input.Register("Ultimate", 9)
    :DefineSequence({
        Enum.KeyCode.Q,
        Enum.KeyCode.W,
        Enum.KeyCode.E
    }, 1.0) -- 1 second window

Ultimate.OnBegan:Connect(function()
    player:executeUltimate()
end)
```

### UI Binding

```lua
local Shop = Input.Register("Shop", 8)
    :Define(Enum.KeyCode.B)
    :DefineUI(script.Parent.ShopButton)

Shop.OnBegan:Connect(function()
    toggleShop()
end)
```

One action handles keyboard and UI button. Same priority system.

### Critical Priority

```lua
local Menu = Input.Register("Menu", Input.CRITICAL_PRIORITY)
    :Define(Enum.KeyCode.Escape)

Menu.OnBegan:Connect(function()
    openMenu()
end)
```

Never blocked, even when other inputs are disabled.

### Runtime Remapping

```lua
local reader = Input.ReadInput("BindAttack", 1, 5)
reader:Connect(function(input)
    Attack:Remap(input.KeyCode)
end)
```

Captures the next keypress and rebinds automatically.

## Why Use ArcLight?

**DIY approach:**
- Input checks in 5+ scripts
- Manual state flags everywhere
- UI buttons duplicate code
- Combos need custom timers
- Remapping = rewrite everything

**With ArcLight:**
- Register once per action
- Priority is automatic
- UI and keyboard share one code path
- Sequences tracked automatically
- Remapping is one line

## Tested in Production

Used in production Roblox games with 10k+ concurrent users. The API is stable and follows semantic versioning — no breaking changes in 1.x releases.

## Documentation

See [GitHub README](https://github.com/nontkph/ArcLight-Input) for full API reference and advanced examples.

## Links

- **Source Code**: https://github.com/nontkph/ArcLight-Input
- **Wally Package**: https://wally.run/package/nontkph/arclightinput
- **Creator**: https://www.roblox.com/users/964473790/profile
- **Discord**: https://discord.com/users/856819327524012033

---

Questions, bugs, or feedback? Open an issue on GitHub or reach out.
