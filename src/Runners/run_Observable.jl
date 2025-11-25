# ============================================================================
# OBSERVABLE CALCULATION RUNNER
# ============================================================================
#
# This module provides functionality for calculating observables on saved
# MPS data from tensor network simulations.
#
# RESPONSIBILITIES:
# - Load simulation config and find simulation data
# - Load MPS for specified sweeps
# - Calculate requested observables
# - Save results using database functions
#
# DATABASE/SAVING:
# - Uses Database_observable_utils.jl functions for saving
#
# ============================================================================

using JSON
using JLD2
using LinearAlgebra

# ============================================================================
# PART 1: Operator Builders
# ============================================================================

"""
    _build_operator_from_config(op_config) → Matrix

Convert operator specification to actual matrix.

# Arguments
- `op_config`: Either a string ("Sx", "Sy", "Sz", "Sp", "Sm") or a matrix

# Returns
- Matrix representation of the operator

# Example
```julia
Sz = _build_operator_from_config("Sz")
custom_op = _build_operator_from_config([[0.5, 0], [0, -0.5]])
```
"""
function _build_operator_from_config(op_config)
    # If already a matrix, return it
    if op_config isa AbstractArray
        return op_config
    end
    
    # Otherwise, build from string
    if op_config == "Sz"
        return [0.5 0.0; 0.0 -0.5]
    elseif op_config == "Sx"
        return [0.0 0.5; 0.5 0.0]
    elseif op_config == "Sy"
        return [0.0 -0.5im; 0.5im 0.0]
    elseif op_config == "Sp"
        return [0.0 1.0; 0.0 0.0]
    elseif op_config == "Sm"
        return [0.0 0.0; 1.0 0.0]
    else
        error("Unknown operator: $op_config. Use 'Sx', 'Sy', 'Sz', 'Sp', 'Sm' or provide matrix")
    end
end

# ============================================================================
# PART 2: Sweep Selection
# ============================================================================

"""
    _get_sweeps_to_process(sweep_config, run_dir) → Vector{Int}

Determine which sweeps to process based on sweep selection config.

# Arguments
- `sweep_config::Dict`: Sweep selection configuration
- `run_dir::String`: Path to simulation run directory

# Returns
- Vector of sweep numbers to process

# Sweep Selection Types
- "all": Process all available sweeps
- "range": Process sweeps in [start, end]
- "specific": Process specific list of sweeps
- "time_range": For TDVP, process sweeps in time range (converts to sweep numbers)

# Example
```json
{"selection": "all"}
{"selection": "range", "range": [1, 50]}
{"selection": "specific", "list": [1, 10, 20, 50]}
{"selection": "time_range", "time_range": [0.0, 1.0]}  // TDVP only
```
"""
function _get_sweeps_to_process(sweep_config::Dict, run_dir::String)
    selection = sweep_config["selection"]
    
    # Load metadata to get available sweeps
    metadata_path = joinpath(run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    available_sweeps = [entry["sweep"] for entry in metadata["sweep_data"]]
    
    if selection == "all"
        return available_sweeps
        
    elseif selection == "range"
        start_sweep, end_sweep = sweep_config["range"]
        return filter(s -> start_sweep <= s <= end_sweep, available_sweeps)
        
    elseif selection == "specific"
        requested = sweep_config["list"]
        return filter(s -> s in requested, available_sweeps)
        
    elseif selection == "time_range"
        # Only for TDVP runs
        if !haskey(metadata, "dt")
            error("time_range selection only valid for TDVP runs")
        end
        
        t_start, t_end = sweep_config["time_range"]
        
        # Filter sweeps by time
        selected_sweeps = Int[]
        for entry in metadata["sweep_data"]
            if haskey(entry, "time")
                t = entry["time"]
                if t_start <= t <= t_end
                    push!(selected_sweeps, entry["sweep"])
                end
            end
        end
        
        return selected_sweeps
        
    else
        error("Unknown sweep selection: $selection. Use 'all', 'range', 'specific', or 'time_range'")
    end
end

# ============================================================================
# PART 3: Observable Calculation Dispatcher
# ============================================================================

"""
    _calculate_observable(obs_type, params, mps, ham) → value

Dispatch to appropriate observable function based on type.

# Arguments
- `obs_type::String`: Observable type (matches function names in Analysis/)
- `params::Dict`: Observable-specific parameters
- `mps::Vector`: MPS tensors
- `ham::Vector`: Hamiltonian MPO (optional, only for energy observables)

# Returns
- Calculated observable value (type depends on observable)
"""
function _calculate_observable(obs_type::String, params::Dict, mps::Vector{<:AbstractArray{T1,3}}, ham::Union{Vector{<:AbstractArray{T2,4}},Nothing}=nothing) where {T1,T2}
    
    if obs_type == "single_site_expectation"
        site = params["site"]
        operator = _build_operator_from_config(params["operator"])
        return single_site_expectation(site, operator, mps)
        
    elseif obs_type == "subsystem_expectation_sum"
        operator = _build_operator_from_config(params["operator"])
        l = params["l"]
        m = params["m"]
        return subsystem_expectation_sum(operator, mps, l, m)
        
    elseif obs_type == "two_site_expectation"
        site_i = params["site_i"]
        site_j = params["site_j"]
        op_i = _build_operator_from_config(params["operator_i"])
        op_j = _build_operator_from_config(params["operator_j"])
        return two_site_expectation(site_i, op_i, site_j, op_j, mps)
        
    elseif obs_type == "correlation_function"
        site_i = params["site_i"]
        site_j = params["site_j"]
        operator = _build_operator_from_config(params["operator"])
        return correlation_function(site_i, site_j, operator, mps)
        
    elseif obs_type == "connected_correlation"
        site_i = params["site_i"]
        site_j = params["site_j"]
        operator = _build_operator_from_config(params["operator"])
        return connected_correlation(site_i, site_j, operator, mps)
        
    elseif obs_type == "entanglement_spectrum"
        bond = params["bond"]
        n_values = get(params, "n_values", nothing)
        return entanglement_spectrum(bond, mps; n_values=n_values)
        
    elseif obs_type == "entanglement_entropy"
        bond = params["bond"]
        alpha = get(params, "alpha", 1)
        return entanglement_entropy(bond, mps; alpha=alpha)
        
    elseif obs_type == "energy_expectation"
        if ham === nothing
            error("energy_expectation requires Hamiltonian")
        end
        return energy_expectation(mps, ham)
        
    elseif obs_type == "energy_variance"
        if ham === nothing
            error("energy_variance requires Hamiltonian")
        end
        return energy_variance(mps, ham)
        
    else
        error("Unknown observable type: $obs_type")
    end
end

# ============================================================================
# PART 4: Main Observable Runner (With Database Integration)
# ============================================================================

"""
    run_observable_calculation_from_config(obs_config; base_dir="data", obs_base_dir="observables")
        -> (String, String)

Main entry point for observable calculations with automatic saving.

# Arguments
- `obs_config::Dict`: Observable configuration
- `base_dir::String`: Base directory for simulation data (default: "data")
- `obs_base_dir::String`: Base directory for observable data (default: "observables")

# Returns
- `(obs_run_id, obs_run_dir)`: Observable run identifier and directory

# Workflow
1. Load simulation config from referenced file
2. Find simulation run using config hash
3. Setup observable directory structure
4. For each sweep:
   - Load MPS
   - Calculate observable
   - Save immediately
5. Finalize metadata

# Example
```julia
obs_config = JSON.parsefile("configs/obs_magnetization.json")
obs_run_id, obs_run_dir = run_observable_calculation_from_config(obs_config)

# Load results later
results = load_all_observable_results(obs_run_dir)
```
"""
function run_observable_calculation_from_config(obs_config::Dict; 
                                                base_dir::String="data",
                                                obs_base_dir::String="observables")
    println("="^70)
    println("Starting Observable Calculation from Config")
    println("="^70)
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 1: Load Simulation Config and Find Run
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[1/5] Loading simulation config and finding run...")
    
    sim_config_file = obs_config["simulation"]["config_file"]
    
    if !isfile(sim_config_file)
        error("Simulation config file not found: $sim_config_file")
    end
    
    sim_config = JSON.parsefile(sim_config_file)
    println("  ✓ Loaded simulation config: $sim_config_file")
    
    # Find runs with this config
    runs = _find_runs_by_config(sim_config, base_dir)
    
    if isempty(runs)
        error("No simulation data found for this config!\n" *
              "Run the simulation first with: run_simulation_from_config()")
    end
    
    # Select run (use latest if multiple)
    if length(runs) == 1
        run_info = runs[1]
        println("  ✓ Found simulation run: $(run_info["run_id"])")
    else
        run_info = _get_latest_run_for_config(sim_config, base_dir=base_dir)
        println("  ⚠ Multiple runs found, using latest: $(run_info["run_id"])")
        println("    (Found $(length(runs)) runs total)")
    end
    
    sim_run_id = run_info["run_id"]
    sim_run_dir = run_info["run_dir"]
    algorithm = sim_config["algorithm"]["type"]
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 2: Setup Observable Directory (NEW!)
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[2/5] Setting up observable directory...")
    
    # NEW: Setup observable directory structure
    obs_run_id, obs_run_dir = _setup_observable_directory(obs_config, sim_run_id, algorithm, 
                                                         obs_base_dir=obs_base_dir)
    
    println("  ✓ Observable run ID: $obs_run_id")
    println("  ✓ Observable directory: $obs_run_dir")
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 3: Determine Sweeps to Process
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[3/5] Determining sweeps to process...")
    
    sweeps_to_process = _get_sweeps_to_process(obs_config["sweeps"], sim_run_dir)
    
    println("  ✓ Sweeps to process: $(length(sweeps_to_process))")
    println("    Range: $(minimum(sweeps_to_process)) to $(maximum(sweeps_to_process))")
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 4: Load Hamiltonian if Needed
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[4/5] Preparing observable calculation...")
    
    obs_type = obs_config["observable"]["type"]
    obs_params = obs_config["observable"]["params"]
    
    println("  Observable type: $obs_type")
    
    # Check if we need the Hamiltonian
    needs_ham = obs_type in ["energy_expectation", "energy_variance"]
    
    ham = nothing
    if needs_ham
        println("  Building Hamiltonian (needed for energy observables)...")
        ham_mpo = build_mpo_from_config(sim_config)
        ham = ham_mpo.tensors
        println("  ✓ Hamiltonian loaded")
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 5: Calculate and Save Observables for Each Sweep (MODIFIED!)
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[5/5] Calculating and saving observables...")
    println("="^70)
    
    try
        for (idx, sweep) in enumerate(sweeps_to_process)
            # Load MPS for this sweep
            mps, extra_data = load_mps_sweep(sim_run_dir, sweep)
            
            # Calculate observable
            obs_value = _calculate_observable(obs_type, obs_params, mps.tensors, ham)
            
            # NEW: Save immediately after calculation
            _save_observable_sweep(obs_value, obs_run_dir, sweep; extra_data=extra_data)
            
            # Print progress
            if idx % max(1, div(length(sweeps_to_process), 10)) == 0
                println("  Progress: $idx/$(length(sweeps_to_process)) sweeps")
            end
        end
        
        # ════════════════════════════════════════════════════════════════════
        # NEW: Finalize Observable Run
        # ════════════════════════════════════════════════════════════════════
        
        println("="^70)
        println("\n[6/6] Finalizing...")
        _finalize_observable_run(obs_run_dir, status="completed")
        
    catch e
        # If calculation fails, mark as failed
        println("\n❌ Observable calculation failed!")
        _finalize_observable_run(obs_run_dir, status="failed")
        rethrow(e)
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # Return Observable Run Info (CHANGED!)
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n" * "="^70)
    println("Observable Calculation Summary")
    println("="^70)
    println("  Simulation run: $sim_run_id")
    println("  Observable run: $obs_run_id")
    println("  Observable type: $obs_type")
    println("  Sweeps processed: $(length(sweeps_to_process))")
    println("  Results saved in: $obs_run_dir")
    println("="^70)
    
    # NEW: Return only IDs, not results (data is saved)
    return obs_run_id, obs_run_dir
end

# ============================================================================
# PART 5: Convenience Function for Quick Calculation
# ============================================================================

"""
    _calculate_observable_at_sweep(obs_type, params, sim_run_dir, sweep; base_dir="data")

Calculate observable for a single sweep (utility function).

# Arguments
- `obs_type::String`: Observable type
- `params::Dict`: Observable parameters
- `sim_run_dir::String`: Path to simulation run directory
- `sweep::Int`: Sweep number

# Returns
- Observable value

# Example
```julia
obs_value = _calculate_observable_at_sweep(
    "single_site_expectation",
    Dict("operator" => "Sz", "site" => 10),
    "data/tdvp/20241103_142530_a3f5b2c1",
    50
)
```
"""
function _calculate_observable_at_sweep(obs_type::String, params::Dict, 
                                       sim_run_dir::String, sweep::Int)
    # Load MPS
    mps, extra_data = load_mps_sweep(sim_run_dir, sweep)
    
    # Load Hamiltonian if needed
    needs_ham = obs_type in ["energy_expectation", "energy_variance"]
    ham = nothing
    if needs_ham
        # Load simulation config to rebuild Hamiltonian
        sim_config = JSON.parsefile(joinpath(sim_run_dir, "config.json"))
        ham_mpo = build_mpo_from_config(sim_config)
        ham = ham_mpo.tensors
    end
    
    # Calculate and return
    return _calculate_observable(obs_type, params, mps.tensors, ham)
end