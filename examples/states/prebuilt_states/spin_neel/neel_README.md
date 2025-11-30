# Prebuilt Neel State

## Overview

Example using the `neel` prebuilt template. Alternating pattern between two eigenstates.

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
    "name": "neel",
    "params": {
      "spin_direction": "Z",
      "even_state": 1,
      "odd_state": 2
    }
  }
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `spin_direction` | String | "Z" | Eigenbasis ("X", "Y", "Z") |
| `even_state` | Int | 1 | Eigenstate for even sites |
| `odd_state` | Int | 2 | Eigenstate for odd sites |

---

## What It Creates

**Pattern (N=6):**
```
Site 1: (Z, 2)  [odd]
Site 2: (Z, 1)  [even]
Site 3: (Z, 2)  [odd]
Site 4: (Z, 1)  [even]
Site 5: (Z, 2)  [odd]
Site 6: (Z, 1)  [even]
```

**Alternating:** Odd sites get `odd_state`, even sites get `even_state`.

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
- Pattern: |ψ⟩ = |s₁⟩ ⊗ |s₂⟩ ⊗ |s₁⟩ ⊗ |s₂⟩ ⊗ ...

**Memory:** Very small (~N × 2 × 8 bytes)

---

## How It Was Built

### Step 1: Template Selection
```json
"type": "prebuilt",
"name": "neel"
```

### Step 2: Pattern Generation
Template creates alternating label pattern:
```julia
pattern = [
  (direction, odd_state),   # i=1 (odd)
  (direction, even_state),  # i=2 (even)
  (direction, odd_state),   # i=3 (odd)
  ...
]
```

### Step 3: MPS Construction
Builds product state from pattern:
```julia
mps = product_state(sites, pattern)
```

Each site gets tensor for its specified eigenstate.

---

## Usage

```bash
cd examples/states/prebuilt/spin/neel
julia build_state.jl
```

**Output:**
```
Prebuilt Neel State

System: 20 spins
Template: neel

MPS Structure:
  Bond dimensions: [1, 1, 1, ...]
  Memory: 0.31 KB

State Pattern:
  Site 1: (Z, 2)  [odd]
  Site 2: (Z, 1)  [even]
  ...
```

---

## Parameter Variations

**Standard Neel (↑↓↑↓):**
```json
"spin_direction": "Z", "even_state": 1, "odd_state": 2
```

**Inverted Neel (↓↑↓↑):**
```json
"spin_direction": "Z", "even_state": 2, "odd_state": 1
```

**X-basis alternating:**
```json
"spin_direction": "X", "even_state": 1, "odd_state": 2
```

---

## See Also

- **All templates:** `examples/states/prebuilt/README.md`
- **Polarized state:** `examples/states/prebuilt/spin/polarized/`
- **Documentation:** `docs/state_building.md`
