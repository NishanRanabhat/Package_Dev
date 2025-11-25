"""
# Two-Site Observables

Functions for computing two-point correlation functions and expectation values
on MPS states without assuming canonical form.

## Functions
- `two_site_expectation`: ⟨O_i O_j⟩ for specific sites i,j with different operators
- `correlation_function`: ⟨O_i O_j⟩ for same operator at two sites
- `connected_correlation`: ⟨O_i O_j⟩_c = ⟨O_i O_j⟩ - ⟨O_i⟩⟨O_j⟩
- `correlation_matrix`: Full C[i,j] matrix for a range of sites
"""

using LinearAlgebra

# ============================================================================
# Two-Site Expectation Values
# ============================================================================

"""
    two_site_expectation(site_i, op_i, site_j, op_j, psi) → scalar

Compute two-site expectation value ⟨ψ|O_i O_j|ψ⟩ with arbitrary operators.

# Arguments
- `site_i::Int`: First site (must have site_i < site_j)
- `op_i::AbstractArray{T1,2}`: Operator at site i
- `site_j::Int`: Second site (must have site_j > site_i)
- `op_j::AbstractArray{T2,2}`: Operator at site j
- `psi::Vector{<:AbstractArray{T3,3}}`: MPS state

# Returns
- Scalar: ⟨O_i O_j⟩

# Example
```julia
Sz = [0.5 0; 0 -0.5]
Sx = [0 0.5; 0.5 0]

# Different operators
corr = two_site_expectation(5, Sz, 10, Sx, mps)

# Same operators (equivalent to correlation_function)
corr = two_site_expectation(5, Sz, 10, Sz, mps)
```
"""
function two_site_expectation(site_i::Int, op_i::AbstractArray{T1,2},
                              site_j::Int, op_j::AbstractArray{T2,2},
                              psi::Vector{<:AbstractArray{T3,3}}) where {T1, T2, T3}
    N = length(psi)
    
    # Validate input
    @assert 1 ≤ site_i < site_j ≤ N "Must have 1 ≤ site_i < site_j ≤ N"
    
    # Build right environment from [site_j+1, N]
    R = ones(1, 1)
    if site_j < N
        @inbounds for i in reverse(site_j+1:N)
            R = _contract_right(psi[i], R)
        end
    end
    
    # Apply operator at site_j
    R = _contract_right(psi[site_j], R, op_j)
    
    # Contract intermediate sites (if any)
    @inbounds for i in reverse(site_i+1:site_j-1)
        R = _contract_right(psi[i], R)
    end
    
    # Apply operator at site_i
    R = _contract_right(psi[site_i], R, op_i)
    
    # Contract remaining left sites
    @inbounds for i in reverse(1:site_i-1)
        R = _contract_right(psi[i], R)
    end
    
    return R[1]
end

# ============================================================================
# Correlation Functions
# ============================================================================

"""
    correlation_function(site_i, site_j, operator, psi) → scalar

Compute correlation function ⟨O_i O_j⟩ with the same operator at both sites.

Convenience wrapper for two_site_expectation with identical operators.

# Arguments
- `site_i::Int`: First site
- `site_j::Int`: Second site (must have site_j > site_i)
- `operator::AbstractArray{T1,2}`: Operator to apply at both sites
- `psi::Vector{<:AbstractArray{T2,3}}`: MPS state

# Returns
- Scalar: ⟨O_i O_j⟩

# Example
```julia
Sz = [0.5 0; 0 -0.5]
corr = correlation_function(5, 15, Sz, mps)
```
"""
function correlation_function(site_i::Int, site_j::Int,
                              operator::AbstractArray{T1,2},
                              psi::Vector{<:AbstractArray{T2,3}}) where {T1, T2}
    return two_site_expectation(site_i, operator, site_j, operator, psi)
end

"""
    connected_correlation(site_i, site_j, operator, psi) → scalar

Compute connected correlation function ⟨O_i O_j⟩_c = ⟨O_i O_j⟩ - ⟨O_i⟩⟨O_j⟩.

This removes the contribution from uncorrelated fluctuations.

# Arguments
- `site_i::Int`: First site
- `site_j::Int`: Second site
- `operator::AbstractArray{T1,2}`: Operator to measure
- `psi::Vector{<:AbstractArray{T2,3}}`: MPS state

# Returns
- Scalar: ⟨O_i O_j⟩ - ⟨O_i⟩⟨O_j⟩

# Example
```julia
Sz = [0.5 0; 0 -0.5]

# Connected correlation (removes background)
conn_corr = connected_correlation(10, 20, Sz, mps)

# For comparison
raw_corr = correlation_function(10, 20, Sz, mps)
```
"""
function connected_correlation(site_i::Int, site_j::Int,
                               operator::AbstractArray{T1,2},
                               psi::Vector{<:AbstractArray{T2,3}}) where {T1, T2}
    # Compute raw correlation
    raw_corr = correlation_function(site_i, site_j, operator, psi)
    
    # Compute single-site expectations
    exp_i = single_site_expectation(site_i, operator, psi)
    exp_j = single_site_expectation(site_j, operator, psi)
    
    # Return connected part
    return raw_corr - exp_i * exp_j
end

