# Custom XXZ Model

## Overview

Simple example showing how to build the Heisenberg model using custom channels.

**Model:** Heisenberg spin chain  

---

## The Model

### Hamiltonian

```
H =  Σᵢ J_x σˣᵢσˣᵢ₊₁ + J_y σʸᵢσʸᵢ₊₁ +  J_z σᶻᵢσᶻᵢ₊₁ + h Σᵢ σᶻᵢ
```

**Parameters in this example:**
- J_x = J_y = 1.0 
- J_z = 2.0 
- h = 0.5 (transverse field)

**Special cases:**
- J_x = J_y != J_z : XXZ
- J_z = 0: XY model
- J_y = J_z = 0: Transverse field Ising model

---

## Building from Channels

### The 4 Channels

**1. XX Coupling**
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "X",
  "op2": "X",
  "range": 1,
  "strength": 1.0
}
```
Creates: Σᵢ σˣᵢσˣᵢ₊₁

**2. YY Coupling**
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Y",
  "op2": "Y",
  "range": 1,
  "strength": 1.0
}
```
Creates: Σᵢ σʸᵢσʸᵢ₊₁

**3. ZZ Coupling**
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z",
  "op2": "Z",
  "range": 1,
  "strength": 2.0
}
```
Creates: Σᵢ σᶻᵢσᶻᵢ₊₁

**4. Longitudinal Field**
```json
{
  "type": "Field",
  "op": "Z",
  "strength": 0.5
}
```
Creates: Σᵢ σᶻᵢ

---

## Usage

### Run the Example

```bash
cd examples/models/custom/xxz
julia build_model.jl
```

### Expected Output

```
Custom Heisenberg Model - Channel Construction

Channels defined:
  1. FiniteRangeCoupling → XX coupling
  2. FiniteRangeCoupling → YY coupling
  3. FiniteRangeCoupling → ZZ coupling
  4. Field → Longitudinal field

MPO Structure:
  Maximum bond dimension: χ = 5

Summary:
  ✓ Built XXZ model from 4 channels
  ✓ Ready for simulations
```
