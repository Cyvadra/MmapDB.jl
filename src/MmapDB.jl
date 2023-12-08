module MmapDB

using Mmap; using Mmap:mmap

Config = Dict{String,Any}(
	# mark
		"isInitiated" => false,
	# where db data shall be saved
		"dataFolder"  => "/mnt/data/test/",
	# where generated files are writed into
		"cacheFolder" => "/tmp/",
	)
MOD_PATH = replace("$(@__FILE__)", "/src/MmapDB.jl"=>"/src")

function GenerateCode(T::DataType)::Module
	if !IsInitiated()
		throw("Init data folder first!")
	end
	# base values
		tName = string(T)
		tmpNames = string.(fieldnames(T))
		tmpNamesU= uppercasefirst.(tmpNames)
		tmpNamesL= lowercasefirst.(tmpNames)
		tmpTypes = string.(T.types)
		tmpFileName = Config["cacheFolder"] * tName * "." * bytes2hex(rand(UInt8,3)) *  ".jl"
		if isfile(tmpFileName)
			rm(tmpFileName)
		end
		touch(tmpFileName)
		f = open(tmpFileName, "w+")
	# implementations in Main
		s = "import Base:+,-\n"
		s *= "function +(a::Main.$tName, b::Main.$tName)::Main.$tName
			Main.$tName("
		for i in 1:length(tmpNames)
			s *= "a.$(tmpNames[i]) + b.$(tmpNames[i]), "
		end
		s = s[1:end-2]
		s *= ")
			end
		"
		s *= "function -(a::Main.$tName, b::Main.$tName)::Main.$tName
			Main.$tName("
		for i in 1:length(tmpNames)
			s *= "a.$(tmpNames[i]) - b.$(tmpNames[i]), "
		end
		s = s[1:end-2]
		s *= ")
			end
		"
		write(f, s)
	# header
		s = read("$MOD_PATH/tpl.header.jl", String)
		s = replace(s, "__tName__" => tName)
		s = replace(s, "__ConfigDataFolder__" => Config["dataFolder"])
		s = replace(s, "__ConfigModuleFile__" => tmpFileName)
		write(f, s)
	# generate structure
		write(f, "\nmutable struct $(tName)\n")
		s = ""
		for i in 1:length(tmpTypes)
			s *= "\t$(tmpNames[i])::$(tmpTypes[i])\n"
		end
		s *= "end\n"
		s *= "export $tName\n\n"
		write(f, s)
		s = ""
	# body
		s = read("$MOD_PATH/tpl.body.jl", String)
		s = replace(s, "__tName__" => tName)
		s = replace(s, "__ConfigDataFolder__" => Config["dataFolder"])
		write(f, s)
	# GetRow
		s = "
			function GetRow(i::Integer)::Main.$(tName)
				Main.$(tName)("
		for i in 1:length(T.types)
			s *= "
					$(tName)Dict[:$(tmpNames[i])][i],"
		end
		s *= "
					)
				end"
		write(f, s)
	# GetRow batch
		s = "
			function GetRow(v::Vector)::Vector{Main.$(tName)}
				return GetRow.(v)
				end
			function GetRow(v::UnitRange)::Vector{Main.$(tName)}
				return GetRow.(collect(v))
				end"
		write(f, s)
	# SetRow
		s = "
			function SetRow(i,v)::Nothing"
		for i in 1:length(tmpNames)
			s *= "
				$(tName)Dict[:$(tmpNames[i])][i] = v.$(tmpNames[i])"
		end
		s *= "
				return nothing
				end"
		write(f, s)
	# SetRow #2
		s = "
			function SetRow(i, "
		s = s * join(tmpNamesL, ", ")
		s = s * ")::Nothing"
		for i in 1:length(tmpNames)
			s *= "
				$(tName)Dict[:$(tmpNames[i])][i] = $(tmpNamesL[i])"
		end
		s *= "
				return nothing
				end"
		write(f, s)
	# InsertRow
		s = "
			function InsertRow(v)::Nothing
				lock(idLock)
				i = Config[\"lastNewID\"] + 1
				Config[\"lastNewID\"] += 1
				unlock(idLock)"
		for i in 1:length(tmpNames)
			s *= "
				$(tName)Dict[:$(tmpNames[i])][i] = v.$(tmpNames[i])"
		end
		s *= "
				return nothing
				end"
		write(f, s)
	# InsertRow #2
		s = "
			function InsertRow("
		s = s * join(tmpNamesL, ", ")
		s = s * ")::Nothing
				lock(idLock)
				i = Config[\"lastNewID\"] + 1
				Config[\"lastNewID\"] += 1
				unlock(idLock)"
		for i in 1:length(tmpNames)
			s *= "
				$(tName)Dict[:$(tmpNames[i])][i] = $(tmpNamesL[i])"
		end
		s *= "
				return nothing
				end"
		write(f, s)
	# BatchInsert
		s = "
			function BatchInsert(v::Vector)::Nothing
				lock(idLock)
				i = Config[\"lastNewID\"] + 1 : Config[\"lastNewID\"] + length(v)
				ids = collect(i)
				Config[\"lastNewID\"] += length(v)
				unlock(idLock)"
		for i in 1:length(tmpNames)
			s *= "
				$(tName)Dict[:$(tmpNames[i])][ids] = map(x->x.$(tmpNames[i]), v)"
		end
		s *= "
				return nothing
				end"
		write(f, s)
	# extensive functions
		s = ""
		for i in 1:length(T.types)
			s *= "

			function GetField$(tmpNamesU[i])(i::Integer)::$(tmpTypes[i])
				return $(tName)Dict[:$(tmpNames[i])][i]
				end
			function GetField$(tmpNamesU[i])(ids) # ::Vector{$(tmpTypes[i])}
				return $(tName)Dict[:$(tmpNames[i])][ids]
				end
			function SetField$(tmpNamesU[i])(i, v)::Nothing
				$(tName)Dict[:$(tmpNames[i])][i] = v
				return nothing
				end
			function SetFieldDiff$(tmpNamesU[i])(i, v)::Nothing
				$(tName)Dict[:$(tmpNames[i])][i] += v
				return nothing
				end
			"
		end
		write(f, s)
	# module end
		write(f, "\nend\n\n")
	close(f)
	chmod(tmpFileName, 0o777)
	@info "File written as " * Config["cacheFolder"] * tName * ".jl"
	@info "Loading module Table$(tName)"
	return Main.include(tmpFileName)
	end

function Init(dataFolder::String, cacheFolder::String="/tmp/")::Bool
	dataFolder[end] !== '/' ? dataFolder *= "/" : nothing
	cacheFolder[end] !== '/' ? cacheFolder *= "/" : nothing
	isdir(dataFolder) || mkdir(dataFolder)
	isdir(cacheFolder) || mkdir(cacheFolder)
	Config["isInitiated"] = true
	Config["dataFolder"]  = dataFolder
	Config["cacheFolder"] = cacheFolder
	return true
	end

function IsInitiated()::Bool
	return Config["isInitiated"]
	end











end
