#!/usr/bin/env julia
#
# Prebuilt Polarized State Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Prebuilt Polarized State")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "polarized_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: $(config["system"]["N"]) spins")
println("  Template: $(config["state"]["name"])")
println("  Direction: $(config["state"]["params"]["spin_direction"])")
println("  Eigenstate: $(config["state"]["params"]["eigenstate"])")

# Build state
println("\n" * "─"^70)
println("Building MPS from template...")
mps = build_mps_from_config(config)
println("✓ MPS constructed")

# Inspect structure
println("\n" * "="^70)
println("MPS Structure")
println("="^70)

println("\nTensor dimensions [χ_left × d × χ_right]:")
for i in 1:min(5, length(mps.tensors))
    dims = size(mps.tensors[i])
    println("  Site $i: [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end
if length(mps.tensors) > 5
    println("  ...")
    dims = size(mps.tensors[end])
    println("  Site $(length(mps.tensors)): [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end

# Bond dimensions
bond_dims = [size(A, 3) for A in mps.tensors[1:end-1]]
println("\nBond dimensions: ", bond_dims)

# Memory
total_elements = sum(length(A) for A in mps.tensors)
memory_bytes = total_elements * sizeof(Float64)
memory_kb = memory_bytes / 1024
println("Memory: $(round(memory_kb, digits=2)) KB")

println("\n" * "="^70)
println("State Pattern: All sites in (Z, 2) eigenstate")
println("Product state with bond dimension χ = 1")
println("="^70)
