# Prebuilt Model Templates

## Overview

This directory contains examples using TNCodebase's **prebuilt model templates**. These templates provide simple, standardized configurations for common quantum models.

**Advantages of prebuilt templates:**
- ✅ Simple configuration (just parameters)
- ✅ Less error-prone
- ✅ Standard physics guaranteed
- ✅ Quick to set up

**When to use custom channels instead:**
- Non-standard models
- Learning how models are built
- Need full control over every term
- **Spin-boson models requiring rotating-wave approximation** (see note below)

### Important Note: Spin-Boson Coupling

**Prebuilt spin-boson templates** (`ising_dickie`, `long_range_ising_dickie`) use:
```
g(a + a†) Σᵢ σ_dir
```

This couples the same spin operator to both boson creation and annihilation.

**For Tavis-Cummings with rotating-wave approximation:**
```
g(a Σᵢ σ⁺ + a† Σᵢ σ⁻)
```

You need **custom channels** with Sp/Sm operators. See `examples/models/custom/spinboson_longrange/` for the correct implementation.

---

## Available Templates

TNCodebase provides **5 prebuilt templates**:

### Spin-Only Models

1. **transverse_field_ising** - Transverse Field Ising Model
2. **heisenberg** - Heisenberg Model 
3. **long_range_ising** - Long-range Ising with FSM

### Spin-Boson Models

4. **ising_dickie** - Ising-Dicke Model (short-range + cavity)
5. **long_range_ising_dickie** - Long-range Ising-Dicke (FSM + cavity)

---

## Template 1: transverse_field_ising

### Hamiltonian

```
H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ
```

### Configuration

```json
{
  "model": {
    "name": "transverse_field_ising",
    "params": {
      "N": 20,
      "J": -1.0,
      "h": 0.5,
      "coupling_dir": "Z",
      "field_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N` | Int | Yes | - | Number of sites |
| `J` | Float | Yes | - | Coupling strength |
| `h` | Float | Yes | - | Field strength |
| `coupling_dir` | String | No | "Z" | Coupling operators ("X", "Y", or "Z") |
| `field_dir` | String | No | "X" | Field operator ("X", "Y", or "Z") |
| `dtype` | String | No | "Float64" | Data type |

### Examples

**Standard TFIM:**
```json
"J": -1.0, "h": 0.5, "coupling_dir": "Z", "field_dir": "X"
```
→ H = -Σᵢ ZᵢZᵢ₊₁ + 0.5Σᵢ Xᵢ

**Ising in different basis:**
```json
"J": 1.0, "h": 0.2, "coupling_dir": "X", "field_dir": "Z"
```
→ H = Σᵢ XᵢXᵢ₊₁ + 0.2Σᵢ Zᵢ

### See Example

`examples/models/prebuilt/tfim/`

---

## Template 2: heisenberg

### Hamiltonian

```
H = Jx Σᵢ σˣᵢσˣᵢ₊₁ + Jy Σᵢ σʸᵢσʸᵢ₊₁ + Jz Σᵢ σᶻᵢσᶻᵢ₊₁ + hx Σᵢ σˣᵢ + hy Σᵢ σʸᵢ + hz Σᵢ σᶻᵢ
```

**Note:** This is actually an XXZ-type model with independent couplings and fields in each direction.

### Configuration

```json
{
  "model": {
    "name": "heisenberg",
    "params": {
      "N": 20,
      "Jx": 1.0,
      "Jy": 1.0,
      "Jz": 1.0,
      "hx": 0.0,
      "hy": 0.0,
      "hz": 0.0,
      "dtype": "ComplexF64"
    }
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N` | Int | Yes | - | Number of sites |
| `Jx` | Float | Yes | - | XX coupling strength |
| `Jy` | Float | Yes | - | YY coupling strength |
| `Jz` | Float | Yes | - | ZZ coupling strength |
| `hx` | Float | Yes | - | Field in X direction |
| `hy` | Float | Yes | - | Field in Y direction |
| `hz` | Float | Yes | - | Field in Z direction |
| `dtype` | String | Yes | "ComplexF64" | Data type |

### Examples

**Isotropic Heisenberg (SU(2) symmetric):**
```json
"Jx": 1.0, "Jy": 1.0, "Jz": 1.0, "hx": 0.0, "hy": 0.0, "hz": 0.0
```
→ H = Σᵢ (XᵢXᵢ₊₁ + YᵢYᵢ₊₁ + ZᵢZᵢ₊₁)

**XXZ model:**
```json
"Jx": 1.0, "Jy": 1.0, "Jz": 2.0, "hx": 0.0, "hy": 0.0, "hz": 0.0
```
→ H = Σᵢ (XᵢXᵢ₊₁ + YᵢYᵢ₊₁ + 2ZᵢZᵢ₊₁)

**With longitudinal field:**
```json
"Jx": 1.0, "Jy": 1.0, "Jz": 1.0, "hx": 0.0, "hy": 0.0, "hz": 0.5
```
→ H = Σᵢ (XᵢXᵢ₊₁ + YᵢYᵢ₊₁ + ZᵢZᵢ₊₁) + 0.5Σᵢ Zᵢ

### Note

This template provides full flexibility for XXZ-type models. Set Jx=Jy=Jz for isotropic Heisenberg.

---

## Template 3: long_range_ising

### Hamiltonian

```
H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σˣᵢ
```

**Uses FSM decomposition automatically!**

### Configuration

```json
{
  "model": {
    "name": "long_range_ising",
    "params": {
      "N": 30,
      "J": 1.0,
      "alpha": 1.5,
      "n_exp": 10,
      "h": 0.0,
      "coupling_dir": "Z",
      "field_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N` | Int | Yes | - | Number of sites |
| `J` | Float | Yes | - | Coupling strength |
| `alpha` | Float | Yes | - | Power-law exponent α |
| `n_exp` | Int | Yes | - | Number of exponentials for FSM |
| `h` | Float | No | 0.0 | Field strength |
| `coupling_dir` | String | No | "Z" | Coupling operators |
| `field_dir` | String | No | "X" | Field operator |
| `dtype` | String | No | "Float64" | Data type |

### Parameter Guide

**alpha (power-law exponent):**
- α < 1: Very long-range (nearly mean-field)
- α = 1.5: Intermediate (this is common)
- α = 3: Dipolar interactions
- α > 3: Approaching short-range

**n_exp (number of exponentials):**
- Rule of thumb: `n_exp ~ log(N) + 5`
- For N=30: n_exp=10 works well
- For N=100: n_exp=12-14 works well
- Larger n_exp → more accurate, larger bond dimension

### Examples

**Dipolar interactions:**
```json
"J": 1.0, "alpha": 3.0, "n_exp": 10
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/|i-j|³

**Very long-range:**
```json
"J": 1.0, "alpha": 0.5, "n_exp": 12
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/√|i-j|

### FSM Efficiency

**Bond dimension:**
- With FSM: χ ~ n_exp + 2 ≈ 12
- Without FSM: χ ~ N ≈ 30
- **Reduction: 2-50× depending on N!**

### See Example

`examples/models/prebuilt/long_range_ising/`

---

## Template 4: ising_dickie

### Hamiltonian

```
H = ω b†b + J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σᶻᵢ + g(a + a†) Σᵢ σ_dir^i
```

**Spin-boson system: 1 boson mode + N spins**

**Important:** The spin-boson coupling uses the same spin operator for both `a` and `a†`. For rotating-wave approximation (correct Tavis-Cummings with Sp/Sm operators), use custom channels instead.

### Configuration

```json
{
  "model": {
    "name": "ising_dickie",
    "params": {
      "N_spins": 20,
      "nmax": 5,
      "J": 1.0,
      "h": 0.0,
      "omega": 1.0,
      "g": 0.2,
      "spin_coupling_dir": "Z",
      "spin_field_dir": "Z",
      "boson_coupling_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N_spins` | Int | Yes | - | Number of spins |
| `nmax` | Int | Yes | - | Boson truncation level |
| `J` | Float | Yes | - | Nearest-neighbor Ising coupling |
| `h` | Float | Yes | - | Longitudinal field on spins |
| `omega` | Float | Yes | - | Boson frequency ω |
| `g` | Float | Yes | - | Spin-boson coupling strength |
| `spin_coupling_dir` | String | Yes | - | Spin-spin coupling direction ("X", "Y", "Z") |
| `spin_field_dir` | String | Yes | - | Field direction ("X", "Y", "Z") |
| `boson_coupling_dir` | String | Yes | - | Spin operator for coupling ("X", "Y", "Z") |
| `dtype` | String | No | "Float64" | Data type |

### Physical Systems

- **Cavity QED:** Atoms in optical cavity
- **Trapped ions:** Ions coupled to phonon mode
- **Circuit QED:** Qubits in microwave resonator

### Examples

**Standard configuration:**
```json
"J": 1.0, "h": 0.0, "omega": 1.0, "g": 0.2,
"spin_coupling_dir": "Z", "spin_field_dir": "Z", "boson_coupling_dir": "X"
```
→ H = ωb†b + Σᵢ ZᵢZᵢ₊₁ + g(a+a†)Σᵢ Xᵢ

**Pure Dicke (no Ising):**
```json
"J": 0.0, "h": 0.0, "omega": 1.0, "g": 0.3, "boson_coupling_dir": "X"
```
→ H = ωb†b + g(a+a†)Σᵢ Xᵢ

### Important Note on Coupling Form

**This template uses:** g(a + a†) Σᵢ σ_dir

**For correct Tavis-Cummings** (excitation-conserving): g(a Σᵢ σ⁺ + a† Σᵢ σ⁻)

Use **custom channels** if you need the rotating-wave approximation form. See `examples/models/custom/spinboson_longrange/` for how to build with Sp/Sm operators.

---

## Template 5: long_range_ising_dickie

### Hamiltonian

```
H = ω b†b + J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σᶻᵢ + g(a + a†) Σᵢ σ_dir^i
```

**Combines FSM + spin-boson coupling**

**Important:** The spin-boson coupling uses the same spin operator for both `a` and `a†`. For rotating-wave approximation (correct Tavis-Cummings with Sp/Sm operators), use custom channels instead.

### Configuration

```json
{
  "model": {
    "name": "long_range_ising_dickie",
    "params": {
      "N_spins": 20,
      "nmax": 5,
      "J": 1.0,
      "alpha": 1.5,
      "n_exp": 10,
      "h": 0.0,
      "omega": 1.0,
      "g": 0.2,
      "spin_coupling_dir": "Z",
      "spin_field_dir": "Z",
      "boson_coupling_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### Parameters

All parameters from `ising_dickie` plus:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `alpha` | Float | Yes | - | Power-law exponent α |
| `n_exp` | Int | Yes | - | Number of exponentials for FSM |

**See `long_range_ising` for guidance on choosing alpha and n_exp.**

### Physical Systems

- **Trapped ions:** Coulomb interaction + phonon coupling
- **Rydberg cavity QED:** Dipolar + photon coupling
- **Advanced cavity systems:** Long-range mediated interactions

### Examples

**Coulomb + cavity:**
```json
"J": 1.0, "alpha": 0.5, "n_exp": 12, "g": 0.2, "omega": 1.0,
"spin_coupling_dir": "Z", "boson_coupling_dir": "X"
```
→ H = ωb†b + Σᵢ<ⱼ ZᵢZⱼ/√|i-j| + g(a+a†)Σᵢ Xᵢ

**Dipolar + cavity:**
```json
"J": 1.0, "alpha": 3.0, "n_exp": 10, "g": 0.2, "omega": 1.0,
"spin_coupling_dir": "Z", "boson_coupling_dir": "X"
```
→ H = ωb†b + Σᵢ<ⱼ ZᵢZⱼ/|i-j|³ + g(a+a†)Σᵢ Xᵢ

### Important Note on Coupling Form

**This template uses:** g(a + a†) Σᵢ σ_dir

**For correct Tavis-Cummings** (excitation-conserving): g(a Σᵢ σ⁺ + a† Σᵢ σ⁻)

Use **custom channels** if you need the rotating-wave approximation form with Sp/Sm operators. See `examples/models/custom/spinboson_longrange/` for the correct implementation.

---

## Quick Reference Table

| Template | Type | Range | FSM | Coupling Form | Complexity |
|----------|------|-------|-----|---------------|------------|
| `transverse_field_ising` | Spin | Nearest | No | - | ★☆☆ |
| `heisenberg` | Spin | Nearest | No | - | ★☆☆ |
| `long_range_ising` | Spin | Power-law | Yes | - | ★★☆ |
| `ising_dickie` | Spin-Boson | Nearest | No | (a+a†)σ | ★★☆ |
| `long_range_ising_dickie` | Spin-Boson | Power-law | Yes | (a+a†)σ | ★★★ |

**Note:** Spin-boson templates use g(a+a†)Σσ coupling. For rotating-wave approximation g(aΣσ⁺+a†Σσ⁻), use custom channels.

---

## Usage Pattern

### 1. Choose Template

Based on your physics:
- **Short-range spins:** `transverse_field_ising` or `heisenberg`
- **Long-range spins:** `long_range_ising`
- **Cavity QED (short-range):** `ising_dickie`
- **Cavity QED (long-range):** `long_range_ising_dickie`

### 2. Set Parameters

See parameter tables above for each template.

### 3. Build Model

```julia
using TNCodebase
using JSON

config = JSON.parsefile("config.json")
mpo = build_mpo_from_config(config)
```

### 4. Use in Simulation

```julia
# DMRG
state, run_id, run_dir = run_simulation_from_config(config)

# Or manual
sites = _build_sites_from_config(config["system"])
mps = build_mps_from_config(config, sites)
# ... run DMRG/TDVP
```

---

## Examples in This Directory

### tfim/

Simple example using `transverse_field_ising` template.

**What it shows:**
- Basic template usage
- Parameter configuration
- Comparison to custom channels

**See:** `tfim/README.md`

### long_range_ising/

Advanced example using `long_range_ising` template with FSM.

**What it shows:**
- FSM automatic decomposition
- Efficiency gains
- Parameter selection guide

**See:** `long_range_ising/README.md`

---

## When to Use Prebuilt vs Custom

### Use Prebuilt When:

✅ You want a standard model (TFIM, Heisenberg, etc.)  
✅ Quick exploration or production runs  
✅ Don't need to understand internal construction  
✅ Want guaranteed correct physics  
✅ Spin-boson coupling g(a+a†)Σσ is sufficient (weak coupling limit)

### Use Custom Channels When:

✅ Non-standard models (unusual interactions, multi-range, etc.)  
✅ Learning how TNCodebase builds models  
✅ Need full control over every term  
✅ Building new models for research  
✅ **Need rotating-wave approximation** g(aΣσ⁺+a†Σσ⁻) for spin-boson models

**See:** `examples/models/custom/` for custom channel examples

---

## Adding New Templates

If you frequently use a model not in the prebuilt list, you can:

**Option 1:** Use custom channels
- Full flexibility
- See `examples/models/custom/`

**Option 2:** Request new template
- Submit issue on GitHub
- Provide Hamiltonian and typical parameters

**Option 3:** Add template yourself
- Modify `src/Builders/modelbuilder.jl`
- Add new template function
- Submit pull request

---

## See Also

- **Custom models:** `examples/models/custom/`
- **Model documentation:** `docs/model_building.md`
- **Channel types:** `docs/model_building.md#channel-types`
- **Quickstart:** `examples/00_quickstart/`

---

## Summary

TNCodebase provides **5 prebuilt templates** covering:
- ✅ Standard spin models (TFIM, Heisenberg)
- ✅ Long-range interactions with FSM
- ✅ Spin-boson systems (cavity QED)
- ✅ Advanced combinations (long-range + cavity)

**For most common models, just specify template name + parameters!**
