#!/usr/bin/env julia
# examples/states/prebuilt/spin/neel/build_state.jl
#
# Prebuilt Neel State Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Prebuilt Neel State")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "neel_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: $(config["system"]["N"]) spins")
println("  Template: $(config["state"]["name"])")
println("  Direction: $(config["state"]["params"]["spin_direction"])")
println("  Even sites: state $(config["state"]["params"]["even_state"])")
println("  Odd sites: state $(config["state"]["params"]["odd_state"])")

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

# Show pattern
println("\n" * "─"^70)
println("State Pattern:")
println("─"^70)
direction = config["state"]["params"]["spin_direction"]
even_state = config["state"]["params"]["even_state"]
odd_state = config["state"]["params"]["odd_state"]

for i in 1:min(8, length(sites))
    state_val = (i % 2 == 1) ? odd_state : even_state
    site_type = (i % 2 == 1) ? "odd" : "even"
    println("  Site $i: ($direction, $state_val)  [$site_type]")
end
if length(sites) > 8
    println("  ...")
end

println("\n" * "="^70)
println("Alternating pattern with bond dimension χ = 1")
println("="^70)
