importPath=string.gsub(getfenv(1)._.Name,"%.LogReader","").."."
import (importPath.."VindarPatch");

string.encode=function(str)
	-- replace all non-alpha characters with a % escaped hex code
	local ret=""
	if str~=nil then
		for i,v in ipairs({str:byte(1,-1)}) do
			if (v < 48) or (v>57 and v<65) or (v>90 and v<97) or (v > 125) then
				ret = ret .. "%" .. string.sub("00"..string.format("%x",tonumber(v)),-2)
			else
				ret = ret .. string.char(v)
			end
		end
	end
	return ret
end

local logName
local cmds=Turbine.Shell.GetCommands();
if cmds~=nil and type(cmds)=="table" then
	table.sort(cmds,function(arg1,arg2)if arg1<arg2 then return(true) end end);
	for cmdIndex=0,#cmds do
		if cmds[cmdIndex]~=nil then
			if cmdIndex>1 and cmds[cmdIndex]>="1" then
				break
			else
				logName=string.match(cmds[cmdIndex],"0ALN_(.*)");
				if logName~=nil then
					break
				end
			end
		end
	end
end
if logName==nil then
	a[1]="Do Not Load This Plugin!"
	return false;
end
respCmd={}
local tmpCmd
log=PatchDataLoad( Turbine.DataScope.Account, "Alerter_Log_"..tostring(logName));
if log~=nil then
	for k,v in ipairs(log) do
		tmpCmd=Turbine.ShellCommand()
		table.insert(respCmd,tmpCmd)
-- argh! need to eliminate the ":" character, it is being seen as an alias for the command
		Turbine.Shell.AddCommand("0ALR_"..string.encode(tostring(v.time)).."_"..string.encode(tostring(v.alert)).."_"..string.encode(v.sender).."_"..tostring(v.channel).."_"..string.encode(tostring(v.response)).."_"..string.encode(tostring(v.message)),tmpCmd);
	end
end

plugin.Unload = function(sender,args)
	-- remove the "0ALR_" commands and the "0ALComplete" command
	for k,v in pairs(respCmd) do
		Turbine.Shell.RemoveCommand(v)
	end
end
tmpCmd=Turbine.ShellCommand()
table.insert(respCmd,tmpCmd)
Turbine.Shell.AddCommand("0ALComplete",tmpCmd);
