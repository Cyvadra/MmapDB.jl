using MmapDB
using Test

@testset "MmapDB.jl" begin
  # neuron.jl
  tmpDir = joinpath(@__DIR__, "MmapDB.test")
  @test MmapDB.Init(tmpDir)
  mutable struct Something
    region_id::UInt8
    longitude::Float64
    latitude::Float64
    timestamp::Int64
  end
  t = MmapDB.GenerateCode(Something)
  # mem test
  @test isnothing(t.CreateMem(10))
  @test isnothing(t.SetFieldLongitude(1,1.23))
  @test t.GetFieldLongitude(1) == 1.23
  @test iszero(t.GetFieldLongitude(2))
  @test isnothing(t.Close())
  # normal test
  @test isnothing(t.Create!(10))
  for i in 1:10
    t.SetFieldRegion_id(i,i)
    t.SetFieldLongitude(i,i/10)
    t.SetFieldLatitude(i,10i)
  end
  @test typeof(t.GetFieldRegion_id(1)) == UInt8
  # search
  @test t.Findfirst(x->x>4, :region_id) == 5
  @test t.SearchSortedFirst(5, :region_id) == 5
  t.Close()
  rm(tmpDir;force=true,recursive=true)
end
