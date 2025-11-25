"""
# Energy Observables

Functions for computing energy-related observables on MPS states.
Works directly with Vector{Array} representation.

## Functions
- `energy_expectation`: ⟨ψ|H|ψ⟩
- `energy_variance`: ⟨H²⟩ - ⟨H⟩²
- `local_energy_density`: Energy contribution at each bond
"""

using LinearAlgebra
using TensorOperations

# ============================================================================
# Energy Expectation Value
# ============================================================================

"""
    energy_expectation(psi, ham) → Float64

Compute energy expectation value ⟨ψ|H|ψ⟩.

Contracts the full MPS-MPO-MPS network by sweeping left to right.

# Arguments
- `psi::Vector{<:AbstractArray{T1,3}}`: MPS state as vector of 3D tensors
- `ham::Vector{<:AbstractArray{T2,4}}`: Hamiltonian as MPO (vector of 4D tensors)

# Returns
- `Float64`: Energy ⟨H⟩

# Example
```julia
E = energy_expectation(mps, hamiltonian)
println("Ground state energy: ", E)
```
"""
function energy_expectation(psi::Vector{<:AbstractArray{T1,3}}, 
                           ham::Vector{<:AbstractArray{T2,4}}) where {T1, T2}
    N = length(psi)
    @assert N == length(ham) "MPS and MPO must have same length"
    
    # Start with left boundary
    L = ones(1, 1, 1)
    
    # Sweep left to right, contracting MPS-MPO-MPS at each site
    @inbounds for i in 1:N
        L = _contract_left(psi[i], L, ham[i])
    end
    
    # Extract scalar energy
    return real(L[1, 1, 1])
end

# ============================================================================
# Energy Variance
# ============================================================================

"""
    energy_variance(psi, ham) → Float64

Compute energy variance ⟨H²⟩ - ⟨H⟩².

Measures how close the state is to an eigenstate:
- Variance = 0: Exact eigenstate
- Variance > 0: Superposition of eigenstates

# Arguments
- `psi::Vector{<:AbstractArray{T1,3}}`: MPS state as vector of 3D tensors
- `ham::Vector{<:AbstractArray{T2,4}}`: Hamiltonian as MPO (vector of 4D tensors)

# Returns
- `Float64`: Energy variance

# Algorithm
1. Compute ⟨H⟩ using energy_expectation
2. Compute ⟨H²⟩ by contracting MPS with H applied twice
3. Return ⟨H²⟩ - ⟨H⟩²

# Example
```julia
E = energy_expectation(mps, hamiltonian)
ΔE = energy_variance(mps, hamiltonian)
println("Energy: E ± (sqrt(ΔE))")

# Check if eigenstate
if ΔE < 1e-10
    println("State is an eigenstate!")
end
```
"""
function energy_variance(psi::Vector{<:AbstractArray{T1,3}}, 
                        ham::Vector{<:AbstractArray{T2,4}}) where {T1, T2}
    N = length(psi)
    @assert N == length(ham) "MPS and MPO must have same length"
    
    # Compute ⟨H⟩
    E = energy_expectation(psi, ham)
    
    # Compute ⟨H²⟩ by applying H twice
    # Contract MPS - MPO - MPO - MPS
    
    # Build left environments with double MPO application
    L = ones(1, 1, 1, 1)  # [left_mps, left_mpo1, left_mpo2, left_mps_conj]
    
    @inbounds for i in 1:N
        # Contract: L - psi[i] - ham[i] - ham[i] - conj(psi[i])
        
        @tensoropt L_new[-1,-2,-3,-4] := conj(psi[i])[6,5,-1]*L[6,7,8,9]*ham[i][7,-2,5,10]*ham[i][8,-3,10,11]*psi[i][9,11,-4]

        L = L_new
    end
    
    # Extract ⟨H²⟩
    E_squared = real(L[1, 1, 1, 1])
    
    # Return variance
    variance = E_squared - E^2
    
    return max(0.0, variance)  # Ensure non-negative (numerical errors)
end
