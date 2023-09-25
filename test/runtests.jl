using MmapDB
using Test

@testset "MmapDB.jl" begin
  # neuron.jl
  tmpDir = joinpath(@__DIR__, "MmapDB.test")
  isdir(tmpDir) || mkdir(tmpDir)
  @test MmapDB.Init(tmpDir)
  mutable struct Something
    region_id::UInt8
    longitude::Float64
    latitude::Float64
    timestamp::Int64
  end
  t = MmapDB.GenerateCode(Something)
  @test isnothing(t.CreateMem(10))
  @test isnothing(t.SetFieldLongitude(1,1.23))
  @test t.GetFieldLongitude(1) == 1.23
  @test iszero(t.GetFieldLongitude(2))
  @test isnothing(t.Close())
  @test isnothing(t.Create!(10))
  @test isnothing(t.SetFieldRegion_id(1,2))
  @test typeof(t.GetFieldRegion_id(1)) == UInt8
  t.Close()
  rm(tmpDir;force=true,recursive=true)
end
