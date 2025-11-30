#!/usr/bin/env julia
# examples/00_quickstart/run_dmrg.jl
#
# Quickstart Example: Complete DMRG Ground State Search
#
# This example demonstrates:
# - Config-driven workflow (everything in config.json)
# - Automatic model building (TFIM using prebuilt template)
# - Random initial state (standard for DMRG)
# - Energy convergence tracking
# - Automatic data saving with hash-based indexing

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("QUICKSTART: DMRG Ground State Search")
println("Transverse Field Ising Model (N=40)")
println("="^70)

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration loaded from: config.json")
println("\n" * "─"^70)
println("SYSTEM:")
println("  Type: $(config["system"]["type"])")
println("  Size: N = $(config["system"]["N"])")

println("\nMODEL: $(config["model"]["name"])")
println("  J (coupling): $(config["model"]["params"]["J"])")
println("  h (field):    $(config["model"]["params"]["h"])")
println("  Coupling dir: $(config["model"]["params"]["coupling_dir"])")
println("  Field dir:    $(config["model"]["params"]["field_dir"])")

println("\nINITIAL STATE: $(config["state"]["type"])")
println("  Bond dimension: $(config["state"]["params"]["bond_dim"])")

println("\nALGORITHM: $(config["algorithm"]["type"])")
println("  Sweeps:       $(config["algorithm"]["run"]["n_sweeps"])")
println("  χ_max:        $(config["algorithm"]["options"]["chi_max"])")
println("  Cutoff:       $(config["algorithm"]["options"]["cutoff"])")
println("  Solver:       $(config["algorithm"]["solver"]["type"])")
println("─"^70)

# ============================================================================
# RUN DMRG SIMULATION
# ============================================================================

println("\nStarting DMRG simulation...")

# Specify data directory relative to package root to save the results
data_dir = joinpath(@__DIR__, "..", "..", "data")

# Run simulation - returns final state, run_id, and run_directory
state, run_id, run_dir = run_simulation_from_config(config, base_dir=data_dir)

println("\n" * "="^70)
println("SIMULATION COMPLETE!")
println("="^70)

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

# Load metadata to get convergence information
metadata_file = joinpath(run_dir, "metadata.json")
metadata = JSON.parsefile(metadata_file)

println("\nRUN INFORMATION:")
println("  Run ID:        $run_id")
println("  Data saved to: $run_dir")

println("\nCONVERGENCE SUMMARY:")
sweep_data = metadata["sweep_data"]
n_sweeps = length(sweep_data)

# First sweep
first_sweep = sweep_data[1]
println("  Sweep 1:")
println("    Energy:     $(first_sweep["energy"])")
println("    Bond dim:   $(first_sweep["max_bond_dim"])")

# Middle sweep (around sweep 10)
mid_idx = min(10, n_sweeps)
mid_sweep = sweep_data[mid_idx]
println("  Sweep $mid_idx:")
println("    Energy:     $(mid_sweep["energy"])")
println("    Bond dim:   $(mid_sweep["max_bond_dim"])")

# Final sweep
final_sweep = sweep_data[end]
println("  Sweep $n_sweeps (final):")
println("    Energy:     $(final_sweep["energy"])")
println("    Bond dim:   $(final_sweep["max_bond_dim"])")

# Energy change in last sweep
if n_sweeps > 1
    prev_energy = sweep_data[end-1]["energy"]
    energy_change = abs(final_sweep["energy"] - prev_energy)
    println("\nCONVERGENCE CHECK:")
    println("  Energy change (last sweep): $(energy_change)")
    if energy_change < 1e-6
        println("  ✓ Converged! (ΔE < 10⁻⁶)")
    else
        println("  ⚠ Not fully converged (ΔE = $(energy_change))")
    end
end

println("\n" * "="^70)
println("PHYSICS INTERPRETATION:")
println("="^70)
println("\nFor TFIM with J=-1.0, h=0.5 (N=40):")
println("  Expected E₀ ≈ -60 to -61 (ferromagnetic phase)")
println("  Your result: E = $(final_sweep["energy"])")
println("\nThis is in the ORDERED PHASE (h < h_c ≈ 1.0)")
println("  → Ground state has net magnetization")
println("  → Spins predominantly aligned in Z direction")
println("  → Quantum fluctuations from transverse field are small")

println("\n" * "="^70)
println("NEXT STEPS:")
println("="^70)
println("\n1. Explore the saved data:")
println("   - MPS states: $run_dir/sweep_*.jld2")
println("   - Metadata:   $run_dir/metadata.json")
println("\n2. Try modifying config.json:")
println("   - Change h to 1.5 (above critical point)")
println("   - Increase N to 60 (larger system)")
println("   - Adjust chi_max (convergence vs speed)")
println("\n3. See other examples:")
println("   - examples/models/ - Learn model building")
println("   - examples/states/ - Learn state preparation")
println("   - examples/tdvp/   - Time evolution")
println("\n4. Read documentation:")
println("   - docs/model_building.md")
println("   - docs/state_building.md")

println("\n" * "="^70)
println("Success! You've run your first DMRG simulation with TNCodebase.")
println("="^70)