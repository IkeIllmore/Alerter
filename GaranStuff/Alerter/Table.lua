
--import "Turbine.Utils";

Table = class();

local function DumpTable( t, indentation, seen )
	if ( t == nil ) then
		Turbine.Shell.WriteLine( indentation .. "(nil)" );
		return;
	end
	seen[t] = true;
	local s= {};
	local n = 0;
	for k in pairs(t) do
		n = n + 1;
		s[n] = k;
	end
	table.sort(s, function(a,b) return tostring(a) < tostring(b) end);
	for k,v in pairs(s) do
		Turbine.Shell.WriteLine( indentation .. tostring( v ) .. ": " .. tostring( t[v] ) );
		if type( t[v] ) == "table" and not seen[t[v]] then
			DumpTable( t[v], indentation .. "  ", seen );
		end
	end
end

Table.Dump = function( t, indentation )
	local seen = {};
	DumpTable( t, indentation or "  ", seen );
end

Table.Copy=function(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
--        return setmetatable(new_table, getmetatable(object))
        return setmetatable(new_table, _copy(getmetatable(object)))
    end
    return _copy(object)
end

