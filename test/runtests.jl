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
  # file test
  @test isnothing(t.Create!(10))
  @test isnothing(t.SetFieldLongitude(1,1.23))
  @test t.GetFieldLongitude(1) == 1.23
  @test iszero(t.GetFieldLongitude(2))
  @test isnothing(t.Close())
  rm(tmpDir;force=true,recursive=true)
  # mem test
  @test isnothing(t.CreateMem(20))
  for i in 1:20
    t.SetFieldRegion_id(i,i)
  end
  @test typeof(t.GetFieldRegion_id(1)) == UInt8
  # search
  @test t.Findfirst(x->x>4, :region_id) == 5
  @test t.SearchSortedFirst(5, :region_id) == 5
  # insert
  t.Close(); t.CreateMem(20)
  for i in 1:5
    t.SetFieldRegion_id(i,i)
    t.SetFieldLongitude(i,i/10)
    t.SetFieldLatitude(i,10i)
    t.SetFieldTimestamp(i,i)
  end
  @test t.alignAI() == 5
  v = Something(11,1.2,3.4,5678)
  t.InsertRow(v); t.InsertRow(v)
  t.BatchInsert([v,v]); t.BatchInsert([v,v])
  @test t.Config["lastNewID"] == 11
  @test isequal(t.GetFieldRegion_id(11),11)
  t.Close()
end
