if importPath==nil then importPath=string.gsub(getfenv(1)._.Name,"%.LogViewer","").."." end
if resourcePath==nil then resourcePath=string.gsub(importPath,"%.","/").."Resources/" end

-- log viewer for Alerter custom logs
import (importPath.."TableView")

-- should "log", listbox and button font change with display font changes?

-- uses separate plugin to load the actual log entries
-- MaxLogSize should be 1000 or less to save time & memory

-- log entries contain {time (yyyy-mm-dd hh:mm:ss.nnn), alert, sender, channel, response, message}

if displayWidth==nil then displayWidth=Turbine.UI.Display:GetWidth() end
if displayHeight==nil then displayHeight=Turbine.UI.Display:GetHeight() end

if Settings.LogViewerWidth==nil then
	Settings.LogViewerWidth=.5
else
	Settings.LogViewerWidth=euroNormalize(Settings.LogViewerWidth)
end
if Settings.LogViewerHeight==nil then
	Settings.LogViewerHeight=.5
else
	Settings.LogViewerHeight=euroNormalize(Settings.LogViewerHeight)
end
if Settings.LogViewerTop==nil then
	Settings.LogViewerTop=.5-Settings.LogViewerHeight/2
else
	Settings.LogViewerTop=euroNormalize(Settings.LogViewerTop)
end
if Settings.LogViewerLeft==nil then
	Settings.LogViewerLeft=.5-Settings.LogViewerWidth/2
else
	Settings.LogViewerLeft=euroNormalize(Settings.LogViewerLeft)
end
if Settings.LogFont==nil then
	Settings.LogFont=Turbine.UI.Lotro.Font.Verdana20
end
logEntries={}
if Settings.LogColumns==nil then
	Settings.LogColumns={[1]={label="Time",name="time",width=100,show=true},[2]={label="Alert",name="alert",width=200,show=true},[3]={label="Sender",name="sender",width=200,show=true},[4]={label="Channel",name="channel",width=100,show=true},[5]={label="Response",name="response",width=200,show=true},[6]={label="Message",name="message",width=200,show=true}}
end

if fontMetric==nil then fontMetric=FontMetric() end
logViewer=Turbine.UI.Lotro.Window()
logViewer:SetZOrder(1)
logViewer:SetSize(Settings.LogViewerWidth*displayWidth,Settings.LogViewerHeight*displayHeight)
logViewer:SetPosition(Settings.LogViewerLeft*displayWidth,Settings.LogViewerTop*displayHeight)
logViewer:SetText(Resource[language][96])
logViewer.LogCaption=Turbine.UI.Label()
logViewer.LogCaption:SetParent(logViewer)
logViewer.LogCaption:SetSize(100,20)
logViewer.LogCaption:SetPosition(10,45)
logViewer.LogCaption:SetText(Resource[language][97])
logViewer.DivWidth=3

logViewer.LogSelect=DropDownList()
logViewer.LogSelect:SetParent(logViewer)
logViewer.LogSelect:SetPosition(logViewer.LogCaption:GetLeft()+logViewer.LogCaption:GetWidth()+logViewer.DivWidth,logViewer.LogCaption:GetTop()-3)
logViewer.LogSelect:SetSize(250,20);
logViewer.LogSelect:SetBorderColor(trimColor);
logViewer.LogSelect:SetBackColor(backColor);
logViewer.LogSelect.CurrentValue:SetBackColor(backColor);
logViewer.LogSelect:SetTextColor(listTextColor);
logViewer.LogSelect:SetDropRows(5);
logViewer.LogSelect:SetZOrder(2);

logViewer.LogSelect:AddItem(Resource[language][98],nil)
for k,v in pairs(customLogList) do
--		local dateTimeStr=tostring(currentDate.Year)..string.sub("00"..tostring(currentDate.Month),-2)..string.sub("00"..tostring(currentDate.Day),-2).."_"..string.sub("00"..tostring(currentDate.Hour),-2)..string.sub("00"..tostring(currentDate.Minute),-2)..string.sub("00"..tostring(currentDate.Second),-2)
	local tmpStr=string.sub(v.dateTime,1,4).."/"..string.sub(v.dateTime,5,6).."/"..string.sub(v.dateTime,7,8).." "..string.sub(v.dateTime,10,11)..":"..string.sub(v.dateTime,12,13)..":"..string.sub(v.dateTime,14,15).." ("..v.name..", "..tostring(v.entries)..")"
	logViewer.LogSelect:AddItem(tmpStr,v.dateTime)
end
logViewer.ShowButton=Turbine.UI.Lotro.Button()
logViewer.ShowButton:SetParent(logViewer)
logViewer.ShowButton:SetSize(100,20)
logViewer.ShowButton:SetPosition(logViewer.LogSelect:GetLeft()+logViewer.LogSelect:GetWidth()+5,logViewer.LogSelect:GetTop())
logViewer.ShowButton:SetText(Resource[language][99])
logViewer.ShowButton.Click=function(sender,args)
	local logName=logViewer.LogSelect:GetValue()
	if logName==nil then
		-- current
		logEntries=customLog
		logViewer.DisplayLog()
	else
		-- get entries from logreader plugin
		logEntries={}
		logViewer.ALNCommand=Turbine.ShellCommand()
		Turbine.Shell.AddCommand("0ALN_"..logName,logViewer.ALNCommand);
		Turbine.PluginManager.LoadPlugin("AlerterLogReader");
		logViewer:SetWantsUpdates(true)
	end
end

logViewer:SetMinimumWidth(510)
logViewer:SetMinimumHeight(150)
logViewer:SetResizable(true)
logViewer.FontSelect=FontSelect()
logViewer.FontSelect:SetParent(logViewer)
logViewer.FontSelect:SetPosition(logViewer:GetWidth()-40,45)
logViewer.FontSelect:SetFont(Settings.LogFont)
logViewer.FontSelect.FontChanged=function()
	Settings.LogFont=logViewer.FontSelect:GetFont()
	logViewer.TableView:SetFont(Settings.LogFont)
	logViewer:SizeChanged() -- trigger a resize event
end

logViewer.Update=function()
	local logName=logViewer.LogSelect:GetValue()

	if Turbine.Shell.IsCommand("0ALComplete") then
		-- reader completed reading
		Turbine.Shell.RemoveCommand(logViewer.ALNCommand)
		logViewer.ALNCommand=nil
		-- read, parse and display the log
		local cmds=Turbine.Shell.GetCommands();
		if cmds~=nil and type(cmds)=="table" then
			if cmds[0]~=nil then
				-- note, there is a bug that can cause GetCommands to return a 0 based array which won't always sort correctly
				table.insert(cmds,cmds[0])
				cmds[0]=nil
			end
			table.sort(cmds,function(arg1,arg2)if arg1<arg2 then return(true) end end);
		end

		for cmdIndex=1,#cmds do
			if cmds[cmdIndex]>="1" then
				break
			else
				local result=string.match(cmds[cmdIndex],"0ALR_(.*)");
				if result~=nil then
					result=string.split(result,"_")
					if result[1]==nil then result[1]="" end
					if result[2]==nil then result[2]="" end
					if result[3]==nil then result[3]="" end
					if result[4]==nil then result[4]="" end
					if result[5]==nil then result[5]="" end
					if result[6]==nil then result[6]="" end
					result[1]=string.decode(result[1])
					result[2]=string.decode(result[2])
					result[3]=string.decode(result[3])
--					result[4]=string.decode(result[4])
					result[5]=string.decode(result[5])
					result[6]=string.decode(result[6])
					table.insert(logEntries,{time=result[1],alert=result[2],sender=result[3], channel=result[4],response=result[5],message=result[6]})
				end
			end
		end

		-- unload the reader
		Turbine.PluginManager.UnloadScriptState("AlerterLogReader");
		logViewer:SetWantsUpdates(false)
		logViewer.DisplayLog()
	end
end

logViewer.TableView=TableView()
logViewer.TableView:SetParent(logViewer)
logViewer.TableView:SetPosition(10,70)
logViewer.TableView:SetFont(Settings.LogFont)
logViewer.TableView:SetSize(logViewer:GetWidth()-20,logViewer:GetHeight()-115)
logViewer.TableView.MouseWheel=function(sender,args)
	if logViewer:IsControlKeyDown() then
		local newFont
		if args.Direction==1 then
			newFont=GetLargerFont(Settings.LogFont)
		else
			newFont=GetSmallerFont(Settings.LogFont)
		end
		if newFont~=nil and newFont~=Settings.LogFont then
			Settings.LogFont=newFont
			logViewer.FontSelect:SetFont(Settings.LogFont)
			logViewer.FontSelect.FontChanged()
		end
	end
end

logViewer.DisplayLog=function()
	logViewer.TableView:ShowTable(Settings.LogColumns,logEntries)
end
logViewer.SizeChanged=function()
	local newWidth,newHeight=logViewer:GetSize()
	logViewer.FontSelect:SetLeft(newWidth-40)
	logViewer.TableView:SetSize(newWidth-20,newHeight-115)
end