# Prebuilt Polarized State

## Overview

Example using the `polarized` prebuilt template. All sites in the same eigenstate.

---

## Configuration

```json
{
  "system": {
    "type": "spin",
    "N": 20,
    "S": 0.5
  },
  "state": {
    "type": "prebuilt",
    "name": "polarized",
    "params": {
      "spin_direction": "Z",
      "eigenstate": 2
    }
  }
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `spin_direction` | String | "Z" | Eigenbasis ("X", "Y", "Z") |
| `eigenstate` | Int | 2 | Which eigenstate (1=lowest, 2=highest) |

---

## What It Creates

**Pattern (N=5):**
```
Site 1: (Z, 2)
Site 2: (Z, 2)
Site 3: (Z, 2)
Site 4: (Z, 2)
Site 5: (Z, 2)
```

**All sites identical:** Each site in the same eigenstate of chosen direction.

---

## Architecture

**MPS Structure:**
```
Site 1: [1 × 2 × 1]
Site 2: [1 × 2 × 1]
...
Site N: [1 × 2 × 1]
```

**Product state:**
- Bond dimension: χ = 1
- No entanglement between sites
- Exact tensor product: |ψ⟩ = |s⟩ ⊗ |s⟩ ⊗ ... ⊗ |s⟩

**Memory:** Very small (~N × 2 × 8 bytes)

---

## How It Was Built

### Step 1: Template Selection
```json
"type": "prebuilt",
"name": "polarized"
```

### Step 2: Pattern Generation
Template creates label pattern:
```julia
pattern = [(direction, eigenstate), (direction, eigenstate), ...]
```

### Step 3: MPS Construction
Builds product state from pattern:
```julia
mps = product_state(sites, pattern)
```

Each site gets tensor for specified eigenstate.

---

## Usage

```bash
cd examples/states/prebuilt/spin/polarized
julia build_state.jl
```

**Output:**
```
Prebuilt Polarized State

System: 20 spins
Template: polarized

MPS Structure:
  Bond dimensions: [1, 1, 1, ...]
  Memory: 0.31 KB

State Pattern: All sites in (Z, 2) eigenstate
```

---

## Parameter Variations

**All spins up (Z):**
```json
"spin_direction": "Z", "eigenstate": 2
```

**All spins down (Z):**
```json
"spin_direction": "Z", "eigenstate": 1
```

**All spins in X direction:**
```json
"spin_direction": "X", "eigenstate": 2
```

---

## See Also

- **All templates:** `examples/states/prebuilt/README.md`
- **Neel state:** `examples/states/prebuilt/spin/neel/`
- **Documentation:** `docs/state_building.md`
