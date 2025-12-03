using Revise
using Test
using TNCodebase
using LinearAlgebra

@testset "TNCodebase.jl" begin
    
    @testset "Core Types" begin
        # Test MPS construction
        tensors = [rand(1, 2, 2), rand(2, 2, 2), rand(2, 2, 1)]
        mps = MPS{Float64}(tensors)
        @test length(mps.tensors) == 3
        @test size(mps.tensors[1]) == (1, 2, 2)
    end
    
    @testset "Operators" begin
        # Test spin operators
        ops = spin_ops(2)
        @test haskey(ops, :X)
        @test haskey(ops, :Y)
        @test haskey(ops, :Z)
        @test size(ops[:X]) == (2, 2)
        
        # Test operator properties
        @test ishermitian(ops[:X])
        @test ishermitian(ops[:Z])
    end
    
    @testset "Canonicalization" begin
        # Test orthogonality operations
        N = 5
        tensors = [rand(ComplexF64, i==1 ? 1 : 4, 2, i==N ? 1 : 4) for i in 1:N]
        mps = MPS{ComplexF64}(tensors)
        
        # Canonicalize at center
        make_canonical(mps, 3)
        
        # Check left orthogonality
        @test is_left_orthogonal(mps.tensors[1])
        @test is_left_orthogonal(mps.tensors[2])
        
        # Check right orthogonality
        @test is_right_orthogonal(mps.tensors[4])
        @test is_right_orthogonal(mps.tensors[5])
    end
        
    @testset "Observables" begin
        # Create simple MPS
        N = 10
        tensors = [rand(ComplexF64, 1, 2, 1) for i in 1:N]
        mps = tensors
        
        # Test single-site expectation
        Sz = [0.5 0; 0 -0.5]
        exp_val = single_site_expectation(5, Sz, mps)
        @test isa(exp_val, Number)
        @test abs(exp_val) <= 0.5  # For spin-1/2
    end
    
    println("\n✓ All basic tests passed!")
    println("\n✓ Add more tests in future!")
end
