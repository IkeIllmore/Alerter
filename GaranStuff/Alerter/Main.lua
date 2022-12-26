importPath=string.gsub(getfenv(1)._.Name,"%.Main","").."."
resourcePath=string.gsub(importPath,"%.","/").."Resources/"
-- alerter allows users to set key phrases to watch for in text and then generates a large, flashy message to warn them
-- todo:

-- %P token for matching a Party member name in a message

-- add Custom Log viewer
-- -- why doesn't Message text contain special characters?

import (importPath.."Class");
import (importPath.."VindarPatch");
import "Turbine";
import "Turbine.Gameplay";
import "Turbine.UI";
import "Turbine.UI.Lotro";
import (importPath.."Table");
import (importPath.."Strings");
import (importPath.."ColorPicker");
import (importPath.."DropDownList");
import (importPath.."RadioButtonGroup");
import (importPath.."FontSupport");
import (importPath.."DebugWindow");

fontMetric=FontMetric()
FlasherFont=Turbine.UI.Lotro.Font.TrajanProBold36;
FlasherColor=Turbine.UI.Color(1,0,0);
AlerterLeft=-1;
AlerterTop=-1;
alertHUDState=true;
alertMainState=false;
alertLogState=false;
logViewerState=false;
customLog={}; -- added for logging 09/08/2012
LogSize=0
displayWidth=Turbine.UI.Display:GetWidth()
displayHeight=Turbine.UI.Display:GetHeight()

fontFace=Turbine.UI.Lotro.Font.Verdana16;
trimColor=Turbine.UI.Color(.3,.3,.3);
fontColor=Turbine.UI.Color(1,1,1);
backColor=Turbine.UI.Color(0,0,0);
listTextColor=Turbine.UI.Color(.9,.9,.9);
localPlayer=Turbine.Gameplay.LocalPlayer:GetInstance();
States={};
Settings={}

logChat=false;

language=1;
locale = "en";
if Turbine.Shell.IsCommand("hilfe") then
	locale = "de";
	language=3;
elseif Turbine.Shell.IsCommand("aide") then
	locale = "fr";
	language=2;
end
if (tonumber("1,000")==1) then
	function euroNormalize(value)
		return tonumber((string.gsub(value,"%.",",")));
	end
else
	function euroNormalize(value)
		return tonumber((string.gsub(value,",",".")));
	end
end

string.split=function(str,separator)
	local tmpArray={};
	local tmpElem;
	str=tostring(str);
	if string.find("^$()%.[]*+-?",separator,1,true)~=nil then separator="%"..separator end
	for tmpElem in string.gmatch(str,"[^"..separator.."]*") do
		table.insert(tmpArray,tmpElem);
	end
	local tmpIndex=1;
	while tmpIndex<=#tmpArray do
		if tmpIndex==#tmpArray and tmpArray[tmpIndex]=="" then
			table.remove(tmpArray,tmpIndex);
		else
			if tmpArray[tmpIndex]=="" and tmpArray[tmpIndex+1]~="" then
				table.remove(tmpArray,tmpIndex);
			else
				tmpIndex=tmpIndex+1;
			end
		end
	end
	return tmpArray;
end
string.ltrim=function(str)
	return (string.gsub(str, "^%s*(.-)", "%1"))
end
string.rtrim=function(str)
	return (string.gsub(str, "^(.-)%s*$", "%1"))
end
string.trim=function(str)
	return (string.gsub(str, "^%s*(.-)%s*$", "%1"))
end
string.encode=function(str)
	-- replace all non-alpha characters with a % escaped hex code
	local ret=""
	for i,v in ipairs({str:byte(1,-1)}) do
		if (v < 48) or (v>57 and v<65) or (v>90 and v<97) or (v > 125) then
			ret = ret .. "%" .. string.sub("00"..string.format("%x",tonumber(v)),-2)
		else
			ret = ret .. string.char(v)
		end
	end
	return ret
end
string.decode=function(str)
	local ret=""
	while string.len(str)~=0 do
		local char=string.sub(str,1,1)
		if char~="%" then
			ret=ret..char
			str=string.sub(str,2,-1)
		else
			local char=string.char(tonumber("0x"..string.sub(str,2,3)))
			ret=ret..char
			str = string.sub(str,4,-1)
		end
	end
	return ret;
end
function AddCallback(object, event, callback)
    if (object[event] == nil) then
        object[event] = callback;
    else
        if (type(object[event]) == "table") then
            table.insert(object[event], callback);
        else
            object[event] = {object[event], callback};
        end
    end
    return callback;
end
function RemoveCallback(object, event, callback)
    if (object[event] == callback) then
        object[event] = nil;
    else
        if (type(object[event]) == "table") then
            local size = table.getn(object[event]);
            for i = 1, size do
                if (object[event][i] == callback) then
                    table.remove(object[event], i);
                    break;
                end
            end
        end
    end
end

function UnloadPlugin()
	-- have to remove all shell commands before unloading or we get a crash to desktop :(
	alertMain:RemoveShellCommands();
	if logViewer~=nil and logViewer.ALNCommand~=nil then
		Turbine.Shell.RemoveCommand(logViewer.ALNCommand)
	end
	SaveData();
	RemoveCallback(Turbine.Chat, "Received", alertMain.alerterReceived);
	Turbine.Shell.WriteLine("Alerter "..Plugins["Alerter"]:GetVersion().." by Garan unloaded");
end

function SaveData()
	Settings.language=language
	if logViewer~=nil then
		Settings.LogViewerWidth=logViewer:GetWidth()/displayWidth
		Settings.LogViewerHeight=logViewer:GetHeight()/displayHeight
		Settings.LogViewerTop=logViewer:GetTop()/displayHeight
		Settings.LogViewerLeft=logViewer:GetLeft()/displayWidth
	end

	PatchDataSave( Turbine.DataScope.Account, "Alerter_Settings", Settings );
	local privateAlerts={};
	local sharedAlerts={};
	for k,v in pairs(Alerts) do
		if v[27]==true then
			table.insert(sharedAlerts,Table.Copy(v))
		else
			table.insert(privateAlerts,Table.Copy(v))
		end
	end
	PatchDataSave( Turbine.DataScope.Character, "Alerter_Alerts", privateAlerts );
	PatchDataSave( Turbine.DataScope.Account, "Alerter_SharedAlerts", sharedAlerts );

	if LogSize>0 then
		local currentDate=Turbine.Engine:GetDate();
		local dateTimeStr=tostring(currentDate.Year)..string.sub("00"..tostring(currentDate.Month),-2)..string.sub("00"..tostring(currentDate.Day),-2).."_"..string.sub("00"..tostring(currentDate.Hour),-2)..string.sub("00"..tostring(currentDate.Minute),-2)..string.sub("00"..tostring(currentDate.Second),-2)
		PatchDataSave( Turbine.DataScope.Account, "Alerter_Log_"..dateTimeStr, customLog );
		table.insert(customLogList,{name=localPlayer:GetName(),dateTime=dateTimeStr,entries=LogSize})
	end

	PatchDataSave( Turbine.DataScope.Account, "Alerter_Log_List", customLogList );
end
function LoadData()
	Settings=PatchDataLoad( Turbine.DataScope.Account, "Alerter_Settings");
	if Settings==nil then Settings={} end
	if Settings[1]~=nil then
		-- convert old settings file to new format
		for k,v in ipairs(Settings) do
			Settings[v[1]]=v[2]
		end
	end
	if Settings.language==nil then
		Settings.language=language
	else
		language=Settings.language
	end
	if Settings.MaxLogSize==nil then
		Settings.MaxLogSize=1000
	end
	Alerts=PatchDataLoad( Turbine.DataScope.Character, "Alerter_Alerts");
	if Alerts==nil then Alerts={} end
	local SharedAlerts=PatchDataLoad( Turbine.DataScope.Account, "Alerter_SharedAlerts");
	if SharedAlerts==nil then SharedAlerts={} end
	for k,v in pairs(Alerts) do
		Alerts[k][27]=false; -- provide default for "shared" to fix bug introduced in 1.06
	end
	for k,v in pairs(SharedAlerts) do
		SharedAlerts[k][27]=true -- provide default for "shared" to fix bug introduced in 1.06
	end
	-- copy the shared alerts to the Alerts table
	for k,v in ipairs(SharedAlerts) do
		table.insert(Alerts,Table.Copy(v))
	end
	for tmpIndex=1,#Alerts do
		if Alerts[tmpIndex][3]~=nil then
			Alerts[tmpIndex][3]=euroNormalize(Alerts[tmpIndex][3])
		end
		if Alerts[tmpIndex][4]~=nil then
			Alerts[tmpIndex][4]=Turbine.UI.Color(euroNormalize(Alerts[tmpIndex][4].R),euroNormalize(Alerts[tmpIndex][4].G),euroNormalize(Alerts[tmpIndex][4].B));
		end
		if Alerts[tmpIndex][6]~=nil then
			Alerts[tmpIndex][6]=euroNormalize(Alerts[tmpIndex][6])
		end
		if Alerts[tmpIndex][9]~=nil then
			Alerts[tmpIndex][9]=euroNormalize(Alerts[tmpIndex][9])
		end
		Alerts[tmpIndex][10]=0; -- set the "next allowed time" to 0
		if Alerts[tmpIndex][11]~=nil then
			Alerts[tmpIndex][11]=euroNormalize(Alerts[tmpIndex][11])
		end
		if Alerts[tmpIndex][12]~=nil then
			Alerts[tmpIndex][12]=euroNormalize(Alerts[tmpIndex][12])
		end
		if Alerts[tmpIndex][13]~=nil then
			Alerts[tmpIndex][13]=euroNormalize(Alerts[tmpIndex][13])
		end
		if Alerts[tmpIndex][14]~=nil then
			Alerts[tmpIndex][14]=euroNormalize(Alerts[tmpIndex][14])
		end
	end
	customLogList=PatchDataLoad( Turbine.DataScope.Account, "Alerter_Log_List");
	if customLogList==nil then customLogList={} end
end
LoadData();
import (importPath.."LogViewer");

alertTemplate=Turbine.UI.Window();
alertTemplate:SetBackground(resourcePath.."Border.jpg");
alertTemplate.Middle=Turbine.UI.Control();
alertTemplate.Middle:SetParent(alertTemplate);
alertTemplate.Middle:SetBackColor(Turbine.UI.Color(0,0,0,0));
alertTemplate.Middle:SetPosition(10,10);
alertTemplate.Middle:SetMouseVisible(false);
alertTemplate.SizeChanged=function()
	local width,height=alertTemplate:GetSize();
	alertTemplate.Middle:SetSize(width-20,height-20);
end
alertTemplate.MoveX=-1;
alertTemplate.MoveY=-1;
alertTemplate.MovingIcon=Turbine.UI.Control();
alertTemplate.MovingIcon:SetParent(alertTemplate);
alertTemplate.MovingIcon:SetSize(32,32);
alertTemplate.MovingIcon:SetBackground(0x410081c0)
alertTemplate.MovingIcon:SetStretchMode(2);
-- for some reason, setting the control's position or size AFTER loading the resource background makes it appear... WEIRD
alertTemplate.MovingIcon:SetPosition(alertTemplate:GetWidth()/2-15,alertTemplate:GetHeight()-21);
alertTemplate.MovingIcon:SetVisible(false);
alertTemplate.MouseDown=function(sender,args)
	alertTemplate.Sizing=false;
	if (args.Y>alertTemplate:GetHeight()-10) and (args.X>alertTemplate:GetWidth()-10) then
		alertTemplate.MoveX=args.X;
		alertTemplate.MoveY=args.Y;
		alertTemplate.MovingIcon:SetLeft(args.X-12);
		alertTemplate.MovingIcon:SetTop(args.Y-12);
		alertTemplate.MovingIcon:SetSize(32,32);
		alertTemplate.MovingIcon:SetBackground(0x41007e20)
		alertTemplate.MovingIcon:SetVisible(true);
	elseif (args.Y>alertTemplate:GetHeight()-10) then
		alertTemplate.MoveY=args.Y;
		alertTemplate.MovingIcon:SetLeft(args.X-22);
		alertTemplate.MovingIcon:SetTop(args.Y-12);
		alertTemplate.MovingIcon:SetSize(32,32);
		alertTemplate.MovingIcon:SetBackground(0x410081c0)
		alertTemplate.MovingIcon:SetVisible(true);
	elseif (args.X>alertTemplate:GetWidth()-10) then
		alertTemplate.MoveX=args.X;
		alertTemplate.MovingIcon:SetLeft(args.X-12);
		alertTemplate.MovingIcon:SetTop(args.Y-22);
		alertTemplate.MovingIcon:SetSize(32,32);
		alertTemplate.MovingIcon:SetBackground(0x410081bf)
		alertTemplate.MovingIcon:SetVisible(true);
	elseif (args.Y<11) then
		alertTemplate.MoveX=args.X;
		alertTemplate.MoveY=args.Y;
		alertTemplate.MovingIcon:SetLeft(args.X-12);
		alertTemplate.MovingIcon:SetTop(args.Y-12);
		alertTemplate.MovingIcon:SetSize(32,32);
		alertTemplate.MovingIcon:SetBackground(0x410000dd)
		alertTemplate.MovingIcon:SetVisible(true);
	else
		alertTemplate.MoveX=-1;
		alertTemplate.MoveY=-1;
	end
end

alertTemplate.MouseMove=function(sender,args)
	if not alertTemplate.Sizing and (alertTemplate.MoveY>-1 and alertTemplate.MoveY<10) then
		if (args.X~=alertTemplate.MoveX or args.Y~= alertTemplate.MoveY) then
			alertTemplate.Moving=true;
			local newLeft=alertTemplate:GetLeft()-(alertTemplate.MoveX-args.X)
			local newTop=alertTemplate:GetTop()-(alertTemplate.MoveY-args.Y)
			if newLeft<0 then newLeft=0 end;
			if newLeft>(displayWidth-alertTemplate:GetWidth()) then newLeft=displayWidth-alertTemplate:GetWidth() end;
			if newTop<0 then newTop=0 end;
			if newTop>(displayHeight-alertTemplate:GetHeight()) then newTop=displayHeight-alertTemplate:GetHeight() end;
			alertTemplate:SetPosition(newLeft,newTop);
			alertMain.LeftText:SetText(newLeft);
			alertMain.LeftPercent:SetText(tostring(math.floor(newLeft/displayWidth*1000+.5)/10).."%")
			alertMain.TopText:SetText(newTop);
			alertMain.TopPercent:SetText(tostring(math.floor(newTop/displayHeight*1000+.5)/10).."%")
		end
	else		
		if (alertTemplate.MoveY>-1) then
			alertTemplate.Sizing=true;
			if args.Y~= alertTemplate.MoveY then
				local newHeight=alertTemplate:GetHeight()-(alertTemplate.MoveY-args.Y);
				if newHeight>(displayHeight-alertTemplate:GetTop()) then newHeight=displayHeight-alertTemplate:GetTop() end;
				if newHeight<21 then newHeight=21 end;
				local newX=args.X-22;
				if newX<-13 then newX=-13 end
				if newX>(alertTemplate:GetWidth()-18) then newX=alertTemplate:GetWidth()-18 end
				alertTemplate.MovingIcon:SetLeft(newX);
				alertTemplate.MovingIcon:SetTop(newHeight-21)
				alertTemplate:SetHeight(newHeight);
				alertTemplate.MoveY=args.Y;
				alertMain.HeightText:SetText(newHeight);
				alertMain.HeightPercent:SetText(tostring(math.floor(newHeight/displayHeight*1000+.5)/10).."%")
			end
		end
		if (alertTemplate.MoveX>-1) then
			alertTemplate.Sizing=true;
			if args.X~= alertTemplate.MoveX then
				local newWidth=alertTemplate:GetWidth()-(alertTemplate.MoveX-args.X);
				if newWidth>(displayWidth-alertTemplate:GetLeft()) then newWidth=displayWidth-alertTemplate:GetLeft() end;
				if newWidth<21 then newWidth=21 end;
				local newY=args.Y-22;
				if newY<-13 then newY=-13 end
				if newY>(alertTemplate:GetHeight()-18) then newY=alertTemplate:GetHeight()-18 end
				alertTemplate.MovingIcon:SetTop(newY);
				alertTemplate.MovingIcon:SetLeft(newWidth-21);
				alertTemplate:SetWidth(newWidth);
				alertTemplate.MoveX=args.X;
				alertMain.WidthText:SetText(newWidth);
				alertMain.WidthPercent:SetText(tostring(math.floor(newWidth/displayWidth*1000+.5)/10).."%")
			end
		end
	end
end
alertTemplate.MouseUp=function(sender,args)
	alertTemplate.Sizing=false;
	alertTemplate.MovingIcon:SetVisible(false);
	alertTemplate.MoveX=-1;
	alertTemplate.MoveY=-1;
end

alertTemplate:SetSize(displayWidth,displayHeight);

alertLog=Turbine.UI.Lotro.Window();
--alertLog:SetBackColor(Turbine.UI.Color(0,0,0));
alertLog:SetText(Resource[language][51]);
alertLog:SetSize(640,480);
alertLog:SetPosition(0,0); -- we can revise this later
alertLog.History=Turbine.UI.ListBox();
alertLog.History:SetParent(alertLog);
alertLog.History:SetSize(608,400);
alertLog.History:SetPosition(10,45);
alertLog.History:SetBackColor(Turbine.UI.Color(.05,.05,.1));
alertLog.VScroll=Turbine.UI.Lotro.ScrollBar();
alertLog.VScroll:SetOrientation(Turbine.UI.Orientation.Vertical);
alertLog.VScroll:SetParent(alertLog);
alertLog.VScroll:SetBackColor(backColor);
alertLog.VScroll:SetPosition(alertLog:GetWidth()-22,45);
alertLog.VScroll:SetWidth(12);
alertLog.VScroll:SetHeight(400);
alertLog.History:SetVerticalScrollBar(alertLog.VScroll);
alertLog.StartButton=Turbine.UI.Lotro.Button();
alertLog.StartButton:SetParent(alertLog);
alertLog.StartButton:SetSize(180,20);
alertLog.StartButton:SetPosition(40,alertLog:GetHeight()-30)
alertLog.StartButton:SetText(Resource[language][57]);
alertLog.StartButton.MouseClick=function()
	logChat=not logChat;
	if logChat then
		alertLog.StartButton:SetText(Resource[language][58])
	else
		alertLog.StartButton:SetText(Resource[language][57])
	end
end
alertLog.ClearButton=Turbine.UI.Lotro.Button();
alertLog.ClearButton:SetParent(alertLog);
alertLog.ClearButton:SetSize(180,20);
alertLog.ClearButton:SetPosition(alertLog:GetWidth()-alertLog.ClearButton:GetWidth()-40,alertLog:GetHeight()-30)
alertLog.ClearButton:SetText(Resource[language][52]);
alertLog.ClearButton.MouseClick=function()
	alertLog.History:ClearItems();
end
alertLog.tmpText=Turbine.UI.Label();
alertLog.tmpText:SetParent(alertLog);
alertLog.tmpText:SetPosition(alertLog:GetWidth()+10,0);
alertLog.tmpText:SetFont(Turbine.UI.Lotro.Font.Verdana14);
alertLog.tmpVScroll=Turbine.UI.Lotro.ScrollBar();
alertLog.tmpVScroll:SetOrientation(Turbine.UI.Orientation.Vertical);
alertLog.tmpVScroll:SetParent(alertLog);
alertLog.tmpVScroll:SetBackColor(backColor);
alertLog.tmpVScroll:SetPosition(0,-11);
alertLog.tmpVScroll:SetWidth(12);
alertLog.tmpVScroll:SetHeight(14);
alertLog.tmpText:SetVerticalScrollBar(alertLog.tmpVScroll);

function GetAlertState(index)
	local suppressionLevel=1;
	-- checks the various states that are assigned to Alert(index) and returns the highest suppression level found
	if index~=nil and Alerts[index]~=nil then
		if Alerts[index][25]~=nil then
			for stateIndex=1,#Alerts[index][25] do
				if Alerts[index][25][stateIndex][1]==1 then
					-- check OOC
					if not localPlayer:IsInCombat() then
						if Alerts[index][25][stateIndex][2]>suppressionLevel then suppressionLevel=Alerts[index][25][stateIndex][2] end
					end
				elseif Alerts[index][25][stateIndex][1]==2 then
					-- check in combat
					if localPlayer:IsInCombat() then
						if Alerts[index][25][stateIndex][2]>suppressionLevel then suppressionLevel=Alerts[index][25][stateIndex][2] end
					end
				end
				if suppressionLevel>2 then
					break;
				end
			end
		end
	end
--Turbine.Shell.WriteLine("AlertState["..tostring(index).."]:"..tostring(suppressionLevel))
	return (suppressionLevel);
end

Flasher=class(Turbine.UI.Window);

function Flasher:Constructor()
	Turbine.UI.Window.Constructor( self );
	self:SetMouseVisible(false);
	self:SetSize(displayWidth,displayHeight);
	self:SetZOrder(1000);
	self.Opacity=.6;
	self.Duration=1;
	self.Interval=.3;
	self.EndTime=0;
	self.Scrolling=false;
	self.Image=Turbine.UI.Control();
	self.Image:SetParent(self);
	self.Image:SetMouseVisible(false);
	self.Quickslot=Turbine.UI.Lotro.Quickslot();
	self.Mask=Turbine.UI.Label();
	self.Mask:SetParent(self);
	self.Mask:SetText("");
	self.Mask:SetBackColor(Turbine.UI.Color(0,0,0,0));
	self.Mask:SetStretchMode(0);
	self.Mask:SetMouseVisible(false);
	self.Message=Turbine.UI.Label();
	self.Message:SetParent(self);
	self.Message:SetSize(self:GetWidth(),self:GetHeight());
	self.Message:SetFont(FlasherFont);
	self.Message:SetForeColor(FlasherColor);
	self.Message:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.Message:SetMouseVisible(false);
	self.Message:SetMultiline(true);
	self.Message:SetStretchMode(3);
	self.Done=false;
	self.UseMousePosition=false;
	self.SetAlert=function(args)
		if args==nil then args={} end
		--index, msg, duration, color, font, interval, left, top, width, height, image, captures, channel, sender, message, qsType, qsData, qsMask, opacity, useMousePosition, scroll, delay, state, qsHideAfterClick, saveToLog, responseLua)
		-- args are passed as a table so that we can manipulate them in the Response Lua snippet
		local userFunc,error,success,result
		success=true
		if args.responseLua~=nil and args.responseLua~="" then
			args.self=self
			userFunc,error=loadstring("return function (args) "..args.responseLua.." end");
			if userFunc==nil then
				Turbine.Shell.WriteLine("Error compiling Response Lua:"..tostring(error));
				success=false
			else
				success,userFunc=pcall(userFunc)
				setfenv(userFunc,getfenv()); -- we set the environment to the current plugin environment
				success,result=pcall(userFunc,args);
				if success then
					if result~=nil and result==false then
						success=false
					end
				else
					Turbine.Shell.WriteLine("Error executing Response Lua:"..tostring(result));
				end
			end
		end
		if success then
			if args.state==nil then args.state=1 end;
			-- if stateLevel==2 then we have to wait for all states for this alert to clear
			-- so we allow the delay timer to run, then check our state until we get a 3 (in which case we just go away) or a 1 in which case we fire as immediate
			self.State=args.state;
			self.Index=args.index;

			if args.captures~=nil and type(args.captures)=="table" then
				-- replace the %x values with the captures
				local tmpCapture;
				for tmpCapture=1,#args.captures do
					args.msg=string.gsub(args.msg,"(%%"..tostring(tmpCapture)..")",args.captures[tmpCapture]);
				end
			end
			if args.qsHideAfterClick==nil then
				args.qsHideAfterClick=false
			end
			if args.delay==nil then
				args.delay=0
			end
			if args.ChatType~=nil then
				args.msg=string.gsub(args.msg,"(%%C)",args.ChatType);
			end
			if args.Sender~=nil then
				args.msg=string.gsub(args.msg,"(%%S)",args.Sender);
			end
			if args.Message~=nil then
				args.msg=string.gsub(args.msg,"(%%M)",args.Message);
			end
			alertTemplate:SetVisible(false);
			if args.color~=nil then
				self.Message:SetForeColor(args.color);
			else
				self.Message:SetForeColor(FlasherColor);
			end
			if args.opacity~=nil then
				self:SetOpacity(args.opacity/100); -- opacity is stored as 0-100
			end
			if args.interval~=nil then
				self.Interval=args.interval;
			else
				self.Interval=.3;
			end
			if args.font~=nil then
				self.Message:SetFont(args.font);
			else
				self.Message:SetFont(FlasherFont);
			end
			if args.duration==nil then
				args.duration=1;
			end
			if args.saveToLog~=nil and args.saveToLog==true then
				if LogSize<Settings.MaxLogSize then
					-- add an entry
					local currentDate=Turbine.Engine:GetDate();
					local 
milliSecond=Turbine.Engine:GetGameTime();
					
milliSecond=math.floor((milliSecond-math.floor(milliSecond))*1000)/1000;
					table.insert(customLog,{time=tostring(currentDate.Year).."-"..string.sub("00"..tostring(currentDate.Month),-2).."-"..string.sub("00"..tostring(currentDate.Day),-2).." "..string.sub("00"..tostring(currentDate.Hour),-2)..":"..string.sub("00"..tostring(currentDate.Minute),-2)..":"..string.sub("00"..tostring(currentDate.Second),-2).."."..string.sub("000"..tostring(milliSecond),-3),alert=Alerts[args.index][1],sender=tostring(args.Sender),channel=tostring(args.channel),response=tostring(args.msg),message=tostring(args.Message)})
					LogSize=LogSize+1
				else
					Turbine.Shell.WriteLine("Unable to add alert log entry, maximum log size exceeded.")
				end
			end
			self.duration=args.duration;
			if args.useMousePosition==nil then args.useMousePosition=false end
			if args.scroll==nil then args.scroll=false end
			self.Scrolling=args.scroll;
			args.width=tonumber(args.width);
			if args.width==nil then args.width=displayWidth end
			args.height=tonumber(args.height);
			if args.height==nil then args.height=displayHeight end
			if args.useMousePosition then
				args.top=Turbine.UI.Display:GetMouseY()/displayHeight*100-args.height/2;
				args.left=Turbine.UI.Display:GetMouseX()/displayWidth*100-args.width/2;
				self.UseMousePosition=true; -- need to retain setting in case there is a delay timer
			else
				args.top=tonumber(args.top);
				args.left=tonumber(args.left);
			end
			if args.top==nil then args.top=0 end
			if args.top+args.height>100 then args.top=100-args.height end
			if args.top<0 then args.top=0 end
			if args.left==nil then args.left=0 end
			if args.left+args.width>100 then args.left=100-args.width end
			if args.left<0 then args.left=0 end
			if args.width==nil or args.width>100 then args.width=100 end
			if args.width<0 then args.width=0 end
			if args.height==nil or args.height>100 then args.height=100 end
			if args.height<0 then args.height=0 end

			self:SetSize(displayWidth*args.width/100,displayHeight*args.height/100);
			self:SetPosition(displayWidth*args.left/100,displayHeight*args.top/100);
			self.Image:SetStretchMode(0);
			if args.image~=nil and args.image~="" then
				self.Image:SetVisible(true);
				self.Image:SetSize(1,1);
				local numImage=tonumber(args.image);
				local success,result;
				if numImage~=nil and numImage~=0 then
					success,result=pcall(Turbine.UI.Control.SetBackground,self.Image,numImage);
				else
					success,result=pcall(Turbine.UI.Control.SetBackground,self.Image,resourcePath..args.image);
				end
				if not success then
					self.Image:SetVisible(false);
				end
				self.Image:SetStretchMode(2);
				local tmpWidth,tmpHeight=self.Image:GetSize();

				self.Image:SetSize(tmpWidth,tmpHeight);
				self.Image:SetStretchMode(1);
				self.Image:SetSize(self:GetWidth(),self:GetHeight());
			else
				self.Image:SetVisible(false);
			end
			if args.scroll then
				local tmpWidth=alertLog.tmpText:GetWidth();
				local maxHeight=displayHeight;
				alertLog.tmpText:SetFont(args.font);
				alertLog.tmpText:SetSize(self:GetWidth(),8);
				alertLog.tmpText:SetText(args.msg);

				while alertLog.tmpVScroll:IsVisible() and alertLog.tmpText:GetHeight()<maxHeight do
					alertLog.tmpText:SetHeight(alertLog.tmpText:GetHeight()+8); -- use 8 pixel increments to speed up process
				end
				-- restore the alertLog size and font
				alertLog.tmpText:SetFont(Turbine.UI.Lotro.Font.Verdana14);
				alertLog.tmpText:SetWidth(tmpWidth);
				local newHeight=alertLog.tmpText:GetHeight();
				if newHeight>self:GetHeight() then newHeight=self:GetHeight() end
				self.Message:SetSize(self:GetWidth(),newHeight);
				if newHeight<self:GetHeight() then
					self.Message:SetTop(self:GetHeight()-newHeight);
				end
			else
				self.Message:SetSize(self:GetWidth(),self:GetHeight());
			end
			self.Mask:SetSize(self.Message:GetSize());
			self.Message:SetText(args.msg);
			self.StartTime=Turbine.Engine.GetGameTime()
			self.EndTime=self.StartTime+args.duration;
			self.ScrollHeight=self.Message:GetTop();
			self.ScrollTime=args.duration;
			if self.Interval==0 then
				self.FlashTime=self.EndTime
			else
				self.FlashTime=Turbine.Engine.GetGameTime()+self.Interval/2;
			end

			if args.qsType~=nil and args.qsType~=1 and args.qsData~=nil then
				local sc=Turbine.UI.Lotro.Shortcut();
				if args.qsType==2 then
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Item)
					-- Turbine disabled the ability to use "generic" items in quickslots (they display but won't actually activate)
					-- need to try to find an "instance" of the item in the backpack

				elseif args.qsType==3 then
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Skill)
				elseif args.qsType==4 then
					if args.captures~=nil and type(args.captures)=="table" then
						-- replace the %x values with the captures
						local tmpCapture;
						for tmpCapture=1,#args.captures do
							args.qsData=string.gsub(args.qsData,"(%%"..tostring(tmpCapture)..")",args.captures[tmpCapture]);
						end
					end
					if args.ChatType~=nil then
						args.qsData=string.gsub(args.qsData,"(%%C)",args.ChatType);
					end
					if args.Sender~=nil then
						args.qsData=string.gsub(args.qsData,"(%%S)",args.Sender);
					end
					if args.Message~=nil then
						args.qsData=string.gsub(args.qsData,"(%%M)",args.Message);
					end
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Alias)
				elseif args.qsType==5 then
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Emote)
				elseif args.qsType==6 then
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Pet)
				elseif args.qsType==7 then
					sc:SetType(Turbine.UI.Lotro.ShortcutType.Hobby)
				end
				sc:SetData(args.qsData)
				local success, result=pcall(Turbine.UI.Lotro.Quickslot.SetShortcut,self.Quickslot,sc)
				if success then
					if args.qsMask==nil then args.qsMask=false end
					self.Quickslot:SetParent(self);
					self.Quickslot.MouseClick=function()
						if args.qsHideAfterClick then
							self.EndTime=0;
						end
					end
					if args.qsType==4 or args.qsMask then
						 -- make use of the glitch in setstretchmode that allows it to show the game interface instead of the lua control behind the current control
						self.Mask:SetVisible(true);
						-- resize the quickslot so that the "alias" text is not displayed
						self.Quickslot:SetPosition(-36,0);
						self.Quickslot:SetSize(self.Message:GetWidth()+36,self.Message:GetHeight());
					else
						self.Mask:SetVisible(false);
						self.Quickslot:SetSize(36,36);
						self.Quickslot:SetPosition((self.Message:GetWidth()-36)/2,(self.Message:GetHeight()-36)/2);
					end
				end
			end
			if args.delay==0 then
				if self.State==1 then
					self:SetVisible(true);
				end
				self.DelayTime=0;
			else
				self.EndTime=self.EndTime+args.delay;
				self.FlashTime=self.FlashTime+args.delay;
				self.DelayTime=self.StartTime+args.delay;
			end
		else
			self.DelayTime=0;
		end
		self:SetWantsUpdates(true);
	end
	self.Update=function()
		local time=Turbine.Engine.GetGameTime();
		if self.Scrolling then
			local percent=1-(time-self.StartTime)/self.ScrollTime
			self.Message:SetTop(self.ScrollHeight*percent)
		end
		if self.DelayTime>0 then
			self.State=GetAlertState(self.Index);
			if self.State==3 then
				self.State=3;
				self:SetWantsUpdates(false);
				self.Image:SetVisible(false);
				self.Message:SetVisible(false);
				self.FlashTime=0;
				self.Quickslot.MouseClick=nil;
				self.Quickslot:SetVisible(false);
				self.Done=true;
				alertMain:SetWantsUpdates(true);
			else
				if time>=self.DelayTime then
					self.DelayTime=0;
					if self.State==1 then
						self:SetVisible(true);
					end
				end
			end
		else
			if self.State==1 then
				if time>=self.EndTime then
					-- message time expired
					self:SetWantsUpdates(false);
					self.Image:SetVisible(false);
					self.Message:SetVisible(false);
					self.FlashTime=0;
					self.Quickslot.MouseClick=nil;
					self.Quickslot:SetVisible(false);
					self.Done=true;
					alertMain:SetWantsUpdates(true);
				elseif time>=self.FlashTime then
					-- flash time expired - toggle message state
					self.Image:SetVisible(not self.Image:IsVisible());
					self.Message:SetVisible(not self.Message:IsVisible() and alertHUDState);
					self.FlashTime=Turbine.Engine.GetGameTime()+self.Interval/2;
				else
					self.Message:SetVisible(alertHUDState); -- Hide UI Hide Alert Mod
				end
			else
				local state=GetAlertState(self.Index);
				if state==3 then
					self.State=3;
					self:SetWantsUpdates(false);
					self.Image:SetVisible(false);
					self.Message:SetVisible(false);
					self.FlashTime=0;
					self.Quickslot.MouseClick=nil;
					self.Quickslot:SetVisible(false);
					self.Done=true;
					alertMain:SetWantsUpdates(true);
				elseif state==1 then
					self.State=1;
					if self.UseMousePosition then
						-- reposition relative to the current mouse location, not the location when the delay started
						-- use absolute not relative height & width since mouse position is already an absolute
						local width,height=self:GetSize();
						local maxWidth=displayWidth;
						local maxHeight=displayHeight;
						top=Turbine.UI.Display:GetMouseY()-height/2;
						left=Turbine.UI.Display:GetMouseX()-width/2;

						if top+height>maxHeight then top=maxHeight-height end
						if top<0 then top=0 end
						if left+width>maxWidth then left=maxWidth-width end
						if left<0 then left=0 end
						self:SetPosition(left,top);
					end

					self:SetVisible(true);
					-- adjust the end time and flash time
					self.StartTime=Turbine.Engine.GetGameTime()
					self.EndTime=self.StartTime+self.Duration;
					if self.Interval==0 then
						self.FlashTime=self.EndTime
					else
						self.FlashTime=Turbine.Engine.GetGameTime()+self.Interval/2;
					end
				end
			end
		end
	end
end

Alerter=class(Turbine.UI.Lotro.Window);
function Alerter:Constructor()
	local tmpIndex;
	Turbine.UI.Lotro.Window.Constructor( self );
	self:SetSize(820,505);
	if AlerterLeft<0 then AlerterLeft=(displayWidth-self:GetWidth())/2 end
	if AlerterTop<0 then AlerterTop=(displayHeight-self:GetHeight())/2 end
	self:SetPosition(AlerterLeft,AlerterTop);
	self:SetText(Resource[language][2])
	self:SetZOrder(1);
	self.AlertDisplays={};
	self.LanguageCaption=Turbine.UI.Label();
	self.LanguageCaption:SetParent(self);
	self.LanguageCaption:SetPosition(10,45);
	self.LanguageCaption:SetSize(100,20);
	self.LanguageCaption:SetText(Resource[language][44]..":");

	self.LanguageList=DropDownList();
	self.LanguageList:SetParent(self);
	self.LanguageList:SetPosition(self.LanguageCaption:GetLeft()+self.LanguageCaption:GetWidth()+2,self.LanguageCaption:GetTop()-3);
--	self.LanguageList:SetSize(self:GetWidth()-(self.LanguageCaption:GetWidth()+self.LanguageCaption:GetLeft())-65,20);
	self.LanguageList:SetSize(250,20);
	self.LanguageList:SetBorderColor(trimColor);
	self.LanguageList:SetBackColor(backColor);
	self.LanguageList.CurrentValue:SetBackColor(backColor);
 	self.LanguageList:SetTextColor(listTextColor);
	self.LanguageList:SetDropRows(3);
	self.LanguageList:SetZOrder(2);

	local tmpLanguage,lngIndex;
	for tmpLanguage in pairs(Resource) do
		self.LanguageList:AddItem(Resource[tmpLanguage][1],tmpLanguage);
	end
	self.LanguageList:SetSelectedIndex(language);

	self.LanguageList.SelectedIndexChanged = function()
		language=self.LanguageList:GetValue();
		self:SetLanguage();
	end

	self.AlertCaption=Turbine.UI.Label();
	self.AlertCaption:SetParent(self);
	self.AlertCaption:SetSize(100,20);
	self.AlertCaption:SetPosition(10,self.LanguageCaption:GetTop()+25);
	self.AlertCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.AlertCaption:SetText(Resource[language][3]..":");
	self.AlertSelect=DropDownList();
	self.AlertSelect:SetParent(self);
	self.AlertSelect:SetSize(250,20);
	self.AlertSelect:SetPosition(self.AlertCaption:GetLeft()+self.AlertCaption:GetWidth()+2,self.AlertCaption:GetTop());
	self.AlertSelect:SetBorderColor(trimColor);
	self.AlertSelect:SetBackColor(backColor);
	self.AlertSelect.CurrentValue:SetBackColor(backColor);
 	self.AlertSelect:SetTextColor(listTextColor);
	self.AlertSelect:SetDropRows(12);
	self.AlertSelect:SetZOrder(1);
	self.AlertSelect.SelectedIndexChanged=function()
		if self.AlertSelect:GetSelectedIndex()>1 then
			local tmpAlertIndex=self.AlertSelect:GetValue();
			local tmpSettingIndex,tmpIndex, tmpFont;
			if Alerts[tmpAlertIndex][1]==nil then
				self.LabelText:SetText("");
			else
				self.LabelText:SetText(Alerts[tmpAlertIndex][1]);
			end
			if Alerts[tmpAlertIndex][2]==nil then
				self.MessageText:SetText("");
			else
				self.MessageText:SetText(Alerts[tmpAlertIndex][2]);
			end
			if Alerts[tmpAlertIndex][3]==nil then
				self.DurationText:SetText("");
			else
				self.DurationText:SetText(Alerts[tmpAlertIndex][3]);
			end
			if Alerts[tmpAlertIndex][4]==nil then
				self.MessageColor:SetColor(FlasherColor);
			else
				self.MessageColor:SetColor(Alerts[tmpAlertIndex][4]);
			end
			tmpSettingIndex=24;
			tmpFont=Alerts[tmpAlertIndex][5];
			if tmpFont==nil then
				tmpFont=FlasherFont;
			end
			for tmpIndex=1,self.FontSelect.ListData:GetItemCount() do
				if self.FontSelect.ListData:GetItem(tmpIndex).DataValue==tmpFont then
					tmpSettingIndex=tmpIndex;
					break;
				end
			end
			self.FontSelect:SetSelectedIndex(tmpSettingIndex);
			if Alerts[tmpAlertIndex][6]==nil then
				self.IntervalText:SetText("");
			else
				self.IntervalText:SetText(Alerts[tmpAlertIndex][6]);
			end
			local m,tmpVal, tmpChannel;
			for tmpIndex=1,#self.ChannelSelect do
				self.ChannelSelect[tmpIndex]:SetChecked(false);
			end
			if Alerts[tmpAlertIndex][7]==nil or type(Alerts[tmpAlertIndex][7])~="table" then
			else
				for tmpIndex=1,#Alerts[tmpAlertIndex][7] do
					for tmpChannel=1,#self.ChannelSelect do
						if Alerts[tmpAlertIndex][7][tmpIndex]==self.ChannelSelect[tmpChannel].Value then
							self.ChannelSelect[tmpChannel]:SetChecked(true);
						end
					end
				end
			end
			self.CustChanText:SetText("");
			if Alerts[tmpAlertIndex][16]~=nil then
				self.CustChanText:SetText(Alerts[tmpAlertIndex][16]);
			end
			if Alerts[tmpAlertIndex][8]==nil then
				self.PatternText:SetText("");
			else
				self.PatternText:SetText(Alerts[tmpAlertIndex][8]);
			end
			if Alerts[tmpAlertIndex][9]==nil then
				self.CooldownText:SetText("");
			else
				self.CooldownText:SetText(Alerts[tmpAlertIndex][9]);
			end
			if Alerts[tmpAlertIndex][24]==nil then
				self.DelayText:SetText("");
			else
				self.DelayText:SetText(Alerts[tmpAlertIndex][24]);
			end
			if Alerts[tmpAlertIndex][11]==nil then
				self.LeftText:SetText("");
				self.LeftPercent:SetText("");
				alertTemplate:SetLeft(0);
			else
				self.LeftText:SetText(Alerts[tmpAlertIndex][11]*displayWidth/100);
				self.LeftPercent:SetText(tostring(math.floor(Alerts[tmpAlertIndex][11]*10+.5)/10).."%");
				alertTemplate:SetLeft(tonumber(self.LeftText:GetText()));
			end
			if Alerts[tmpAlertIndex][12]==nil then
				self.TopText:SetText("");
				self.TopPercent:SetText("");
				alertTemplate:SetTop(0);
			else
				self.TopText:SetText(Alerts[tmpAlertIndex][12]*displayHeight/100);
				self.TopPercent:SetText(tostring(math.floor(Alerts[tmpAlertIndex][12]*10+.5)/10).."%");
				alertTemplate:SetTop(tonumber(self.TopText:GetText()));
			end
			if Alerts[tmpAlertIndex][13]==nil then
				self.WidthText:SetText("");
				self.WidthPercent:SetText("");
				alertTemplate:SetWidth(displayWidth-alertTemplate:GetLeft());
			else
				self.WidthText:SetText(Alerts[tmpAlertIndex][13]*displayWidth/100);
				self.WidthPercent:SetText(tostring(math.floor(Alerts[tmpAlertIndex][13]*10+.5)/10).."%");
				alertTemplate:SetWidth(tonumber(self.WidthText:GetText()));
			end
			if Alerts[tmpAlertIndex][14]==nil then
				self.HeightText:SetText("");
				self.HeightPercent:SetText("");
				alertTemplate:SetHeight(displayHeight-alertTemplate:GetTop());
			else
				self.HeightText:SetText(Alerts[tmpAlertIndex][14]*displayHeight/100);
				self.HeightPercent:SetText(tostring(math.floor(Alerts[tmpAlertIndex][14]*10+.5)/10).."%");
				alertTemplate:SetHeight(tonumber(self.HeightText:GetText()));
			end
			self.ImageText:SetText(Alerts[tmpAlertIndex][15]);
			if Alerts[tmpAlertIndex][17]==nil or Alerts[tmpAlertIndex][17] then
				self.EnabledCB:SetChecked(true);
			else
				self.EnabledCB:SetChecked(false);
			end
			if Alerts[tmpAlertIndex][27]==nil or Alerts[tmpAlertIndex][27]==false then
				self.SharedCB:SetChecked(false);
			else
				self.SharedCB:SetChecked(true);
			end
			if Alerts[tmpAlertIndex][19]~=nil then
				self.QSData:SetText(Alerts[tmpAlertIndex][18]);
				self.QSButtons:SetSelectedChoice(Alerts[tmpAlertIndex][19]);
				self.QSButtons.SelectionChanged();
			else
				self.QSData:SetText("")
				self.QSButtons:SetSelectedChoice(1);
			end
			if Alerts[tmpAlertIndex][20]==nil then
				self.QSMask:SetChecked(false);
			else
				self.QSMask:SetChecked(Alerts[tmpAlertIndex][20]);
			end
			if Alerts[tmpAlertIndex][26]==nil then
				self.QSHideAfterClick:SetChecked(false)
			else
				self.QSHideAfterClick:SetChecked(Alerts[tmpAlertIndex][26]);
			end
			if Alerts[tmpAlertIndex][21]==nil then
				self.OpacityValue:SetValue(60);
			else
				self.OpacityValue:SetValue(Alerts[tmpAlertIndex][21]);
			end
			if Alerts[tmpAlertIndex][22]==nil then
				self.UseMousePosition:SetChecked(false);
			else
				self.UseMousePosition:SetChecked(Alerts[tmpAlertIndex][22]);
			end
			if Alerts[tmpAlertIndex][23]==nil then
				self.UseScrollingText:SetChecked(false);
			else
				self.UseScrollingText:SetChecked(Alerts[tmpAlertIndex][23]);
			end
			States={};
			if Alerts[tmpAlertIndex][25]~=nil then
				for tmpState=1,#Alerts[tmpAlertIndex][25] do
					States[tmpState]={Alerts[tmpAlertIndex][25][tmpState][1],Alerts[tmpAlertIndex][25][tmpState][2]};
				end
			end
			if Alerts[tmpAlertIndex][28]==nil then
				self.SaveToLog:SetChecked(false);
			else
				self.SaveToLog:SetChecked(Alerts[tmpAlertIndex][28]);
			end
			if Alerts[tmpAlertIndex][29]==nil then
				self.TriggerLua:SetText("")
			else
				self.TriggerLua:SetText(Alerts[tmpAlertIndex][29])
			end
			if Alerts[tmpAlertIndex][30]==nil then
				self.ResponseLua:SetText("")
			else
				self.ResponseLua:SetText(Alerts[tmpAlertIndex][30])
			end

			-- set the State selected index to 1
			self.StateList:SetSelectedIndex(1);
			self.StateList:SelectedIndexChanged();
		end
	end

	self.AlertSelect:AddItem(Resource[language][4],0);
	for tmpIndex=1,#Alerts do
		self.AlertSelect:AddItem(Alerts[tmpIndex][1],tmpIndex);
	end

	self.LabelCaption=Turbine.UI.Label();
	self.LabelCaption:SetParent(self);
	self.LabelCaption:SetSize(100,20);
	self.LabelCaption:SetPosition(10,self.AlertCaption:GetTop()+25);
	self.LabelCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.LabelCaption:SetText(Resource[language][5]..":");
	self.LabelText=Turbine.UI.Lotro.TextBox();
	self.LabelText:SetParent(self);
	self.LabelText:SetSize(250,20);
	self.LabelText:SetMultiline(false)
	self.LabelText:SetFont(fontFace);
	self.LabelText:SetPosition(self.LabelCaption:GetLeft()+self.LabelCaption:GetWidth()+2,self.LabelCaption:GetTop());

	self.EnabledCB=Turbine.UI.Lotro.CheckBox()
	self.EnabledCB:SetParent(self);
	self.EnabledCB:SetSize(150,20);
	self.EnabledCB:SetPosition(self.LabelText:GetLeft()+self.LabelText:GetWidth()+10,self.LabelCaption:GetTop());
	self.EnabledCB:SetText(Resource[language][59]);
	self.EnabledCB:SetChecked(true);

	self.SharedCB=Turbine.UI.Lotro.CheckBox()
	self.SharedCB:SetParent(self);
	self.SharedCB:SetSize(150,20);
	self.SharedCB:SetPosition(self.EnabledCB:GetLeft()+self.EnabledCB:GetWidth()+10,self.LabelCaption:GetTop());
	self.SharedCB:SetText(Resource[language][91]);
	self.SharedCB:SetChecked(false);

	self.MessageCaption=Turbine.UI.Label();
	self.MessageCaption:SetParent(self);
	self.MessageCaption:SetSize(100,20);
	self.MessageCaption:SetPosition(10,self.LabelCaption:GetTop()+25);
	self.MessageCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.MessageCaption:SetText(Resource[language][6]..":");
	self.MessageText=Turbine.UI.Lotro.TextBox();
	self.MessageText:SetParent(self);
	self.MessageText:SetSize(self:GetWidth()-self.MessageCaption:GetLeft()-self.MessageCaption:GetWidth()-12,20);
	self.MessageText:SetMultiline(false)
	self.MessageText:SetFont(fontFace);
	self.MessageText:SetPosition(self.MessageCaption:GetLeft()+self.MessageCaption:GetWidth()+2,self.MessageCaption:GetTop());


	self.TriggerTab=Turbine.UI.Label();
	self.TriggerTab:SetParent(self);
	self.TriggerTab:SetSize(100,23);
	self.TriggerTab:SetPosition(10,self.MessageCaption:GetTop()+28);
	self.TriggerTab:SetBackColor(Turbine.UI.Color(.05,.05,.1));
	self.TriggerTab:SetForeColor(Turbine.UI.Color(1,.8,.2));
	self.TriggerTab:SetFont(Turbine.UI.Lotro.Font.Verdana18);
	self.TriggerTab:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.TriggerTab:SetText(Resource[language][69]);
	self.TriggerTab.MouseClick=function()
		self.TriggerPanel:SetVisible(true);
		self.ResponsePanel:SetVisible(false);
		self.LuaPanel:SetVisible(false);

		self.TriggerTab:SetHeight(23);
		self.TriggerTab:SetTop(self.MessageCaption:GetTop()+28);
		self.TriggerTab:SetBackColor(Turbine.UI.Color(.05,.05,.1));
		self.TriggerTab:SetForeColor(Turbine.UI.Color(1,.8,.2));
		self.TriggerTab:SetFont(Turbine.UI.Lotro.Font.Verdana18);
		self.TriggerTab:SetText(Resource[language][69]);
		self.ResponseTab:SetHeight(20);
		self.ResponseTab:SetTop(self.MessageCaption:GetTop()+31);
		self.ResponseTab:SetBackColor(Turbine.UI.Color(.01,.1,.01));
		self.ResponseTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.ResponseTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.ResponseTab:SetText(Resource[language][70]);

		self.LuaTab:SetHeight(20);
		self.LuaTab:SetTop(self.MessageCaption:GetTop()+31);
		self.LuaTab:SetBackColor(Turbine.UI.Color(.2,.1,.01));
		self.LuaTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.LuaTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.LuaTab:SetText(Resource[language][92]);
	end
	self.ResponseTab=Turbine.UI.Label();
	self.ResponseTab:SetParent(self);
	self.ResponseTab:SetSize(100,20);
	self.ResponseTab:SetPosition(120,self.MessageCaption:GetTop()+31);
	self.ResponseTab:SetBackColor(Turbine.UI.Color(.01,.1,.01));
	self.ResponseTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
	self.ResponseTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
	self.ResponseTab:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.ResponseTab:SetText(Resource[language][70]);
	self.ResponseTab.MouseClick=function()
		self.TriggerPanel:SetVisible(false);
		self.ResponsePanel:SetVisible(true);
		self.LuaPanel:SetVisible(false);

		self.ResponseTab:SetHeight(23);
		self.ResponseTab:SetTop(self.MessageCaption:GetTop()+28);
		self.ResponseTab:SetBackColor(Turbine.UI.Color(.05,.1,.05));
		self.ResponseTab:SetForeColor(Turbine.UI.Color(1,.8,.2));
		self.ResponseTab:SetFont(Turbine.UI.Lotro.Font.Verdana18);
		self.ResponseTab:SetText(Resource[language][70]);
		self.TriggerTab:SetHeight(20);
		self.TriggerTab:SetTop(self.MessageCaption:GetTop()+31);
		self.TriggerTab:SetBackColor(Turbine.UI.Color(.01,.01,.1));
		self.TriggerTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.TriggerTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.TriggerTab:SetText(Resource[language][69]);
		self.LuaTab:SetHeight(20);
		self.LuaTab:SetTop(self.MessageCaption:GetTop()+31);
		self.LuaTab:SetBackColor(Turbine.UI.Color(.2,.1,.01));
		self.LuaTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.LuaTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.LuaTab:SetText(Resource[language][92]);
	end

	self.LuaTab=Turbine.UI.Label();
	self.LuaTab:SetParent(self);
	self.LuaTab:SetSize(100,20);
	self.LuaTab:SetPosition(230,self.MessageCaption:GetTop()+31);
	self.LuaTab:SetBackColor(Turbine.UI.Color(.2,.1,.01));
	self.LuaTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
	self.LuaTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
	self.LuaTab:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.LuaTab:SetText(Resource[language][92]);
	self.LuaTab.MouseClick=function()
		self.LuaPanel:SetVisible(true);
		self.TriggerPanel:SetVisible(false);
		self.ResponsePanel:SetVisible(false);

		self.LuaTab:SetHeight(23);
		self.LuaTab:SetTop(self.MessageCaption:GetTop()+28);
		self.LuaTab:SetBackColor(Turbine.UI.Color(.2,.1,.01));
		self.LuaTab:SetForeColor(Turbine.UI.Color(1,.8,.2));
		self.LuaTab:SetFont(Turbine.UI.Lotro.Font.Verdana18);
		self.LuaTab:SetText(Resource[language][92]);
		self.TriggerTab:SetHeight(20);
		self.TriggerTab:SetTop(self.MessageCaption:GetTop()+31);
		self.TriggerTab:SetBackColor(Turbine.UI.Color(.01,.01,.1));
		self.TriggerTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.TriggerTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.TriggerTab:SetText(Resource[language][69]);
		self.ResponseTab:SetHeight(20);
		self.ResponseTab:SetTop(self.MessageCaption:GetTop()+31);
		self.ResponseTab:SetBackColor(Turbine.UI.Color(.01,.1,.01));
		self.ResponseTab:SetForeColor(Turbine.UI.Color(.7,.6,.1));
		self.ResponseTab:SetFont(Turbine.UI.Lotro.Font.Verdana16);
		self.ResponseTab:SetText(Resource[language][70]);
	end

	self.TriggerPanel=Turbine.UI.Control();
	self.TriggerPanel:SetParent(self);
	self.TriggerPanel:SetPosition(10,self.TriggerTab:GetTop()+self.TriggerTab:GetHeight());
	self.TriggerPanel:SetSize(self:GetWidth()-20,self:GetHeight()-55-self.TriggerPanel:GetTop());
	self.TriggerPanel:SetBackColor(Turbine.UI.Color(.05,.05,.1));

	self.ResponsePanel=Turbine.UI.Control();
	self.ResponsePanel:SetParent(self);
	self.ResponsePanel:SetPosition(self.TriggerPanel:GetPosition());
	self.ResponsePanel:SetSize(self.TriggerPanel:GetSize());
	self.ResponsePanel:SetBackColor(Turbine.UI.Color(.05,.1,.05));
	self.ResponsePanel:SetVisible(false);

	self.LuaPanel=Turbine.UI.Control();
	self.LuaPanel:SetParent(self);
	self.LuaPanel:SetPosition(10,self.LuaTab:GetTop()+self.LuaTab:GetHeight());
	self.LuaPanel:SetSize(self:GetWidth()-20,self:GetHeight()-55-self.LuaPanel:GetTop());
	self.LuaPanel:SetBackColor(Turbine.UI.Color(.2,.1,.01));
	self.LuaPanel:SetVisible(false);

	self.DurationCaption=Turbine.UI.Label();
	self.DurationCaption:SetParent(self.ResponsePanel);
	self.DurationCaption:SetSize(100,30);
	self.DurationCaption:SetPosition(10,0);
	self.DurationCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.DurationCaption:SetText(Resource[language][9]..":");
	self.DurationText=Turbine.UI.Lotro.TextBox();
	self.DurationText:SetParent(self.ResponsePanel);
	self.DurationText:SetSize(80,20);
	self.DurationText:SetFont(fontFace);
	self.DurationText:SetPosition(self.DurationCaption:GetLeft()+self.DurationCaption:GetWidth()+2,self.DurationCaption:GetTop()+5);

	self.IntervalCaption=Turbine.UI.Label();
	self.IntervalCaption:SetParent(self.ResponsePanel);
	self.IntervalCaption:SetSize(100,30);
	self.IntervalCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.DurationCaption:GetTop());
	self.IntervalCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.IntervalCaption:SetText(Resource[language][10]..":");
	self.IntervalText=Turbine.UI.Lotro.TextBox();
	self.IntervalText:SetParent(self.ResponsePanel);
	self.IntervalText:SetSize(80,20);
	self.IntervalText:SetFont(fontFace);
	self.IntervalText:SetPosition(self.IntervalCaption:GetLeft()+self.IntervalCaption:GetWidth()+2,self.IntervalCaption:GetTop()+5);

	self.CooldownCaption=Turbine.UI.Label();
	self.CooldownCaption:SetParent(self.ResponsePanel);
	self.CooldownCaption:SetSize(100,30);
	self.CooldownCaption:SetPosition(10,self.DurationCaption:GetTop()+25);
	self.CooldownCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.CooldownCaption:SetText(Resource[language][45]..":");
	self.CooldownText=Turbine.UI.Lotro.TextBox();
	self.CooldownText:SetParent(self.ResponsePanel);
	self.CooldownText:SetSize(80,20);
	self.CooldownText:SetFont(fontFace);
	self.CooldownText:SetPosition(self.CooldownCaption:GetLeft()+self.CooldownCaption:GetWidth()+2,self.CooldownCaption:GetTop()+5);

	self.DelayCaption=Turbine.UI.Label();
	self.DelayCaption:SetParent(self.ResponsePanel);
	self.DelayCaption:SetSize(100,30);
	self.DelayCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.CooldownCaption:GetTop());
	self.DelayCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.DelayCaption:SetText(Resource[language][74]..":");
	self.DelayText=Turbine.UI.Lotro.TextBox();
	self.DelayText:SetParent(self.ResponsePanel);
	self.DelayText:SetSize(80,20);
	self.DelayText:SetFont(fontFace);
	self.DelayText:SetPosition(self.DelayCaption:GetLeft()+self.DelayCaption:GetWidth()+2,self.DelayCaption:GetTop()+5);

	self.UseMousePosition=Turbine.UI.Lotro.CheckBox();
	self.UseMousePosition:SetParent(self.ResponsePanel);
	self.UseMousePosition:SetSize(200,20);
	self.UseMousePosition:SetPosition(self.DurationText:GetLeft(),self.CooldownCaption:GetTop()+30);
	self.UseMousePosition:SetSize(self.ResponsePanel:GetWidth()-self.UseMousePosition:GetLeft()-10,20);
	self.UseMousePosition:SetText(Resource[language][67]);

	self.SaveToLog=Turbine.UI.Lotro.CheckBox();
	self.SaveToLog:SetParent(self.ResponsePanel);
	self.SaveToLog:SetSize(200,20);
	self.SaveToLog:SetPosition(self.IntervalText:GetLeft(),self.CooldownCaption:GetTop()+30);
	self.SaveToLog:SetSize(self.ResponsePanel:GetWidth()-self.SaveToLog:GetLeft()-10,20);
	self.SaveToLog:SetText(Resource[language][90]);

	self.LeftCaption=Turbine.UI.Label();
	self.LeftCaption:SetParent(self.ResponsePanel);
	self.LeftCaption:SetSize(100,20);
	self.LeftCaption:SetPosition(10,self.UseMousePosition:GetTop()+25);
	self.LeftCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.LeftCaption:SetText(Resource[language][46]..":");
	self.LeftText=Turbine.UI.Lotro.TextBox();
	self.LeftText:SetParent(self.ResponsePanel);
	self.LeftText:SetSize(80,20);
	self.LeftText:SetFont(fontFace);
	self.LeftText:SetPosition(self.LeftCaption:GetLeft()+self.LeftCaption:GetWidth()+2,self.LeftCaption:GetTop());
	self.LeftPercent=Turbine.UI.Label();
	self.LeftPercent:SetParent(self.ResponsePanel);
	self.LeftPercent:SetSize(40,20);
	self.LeftPercent:SetPosition(self.LeftText:GetLeft()+self.LeftText:GetWidth()+2,self.LeftCaption:GetTop());
	self.LeftPercent:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.LeftPercent:SetText("");

	self.TopCaption=Turbine.UI.Label();
	self.TopCaption:SetParent(self.ResponsePanel);
	self.TopCaption:SetSize(100,20);
	self.TopCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.LeftCaption:GetTop());
	self.TopCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.TopCaption:SetText(Resource[language][47]..":");
	self.TopText=Turbine.UI.Lotro.TextBox();
	self.TopText:SetParent(self.ResponsePanel);
	self.TopText:SetSize(80,20);
	self.TopText:SetFont(fontFace);
	self.TopText:SetPosition(self.TopCaption:GetLeft()+self.TopCaption:GetWidth()+2,self.TopCaption:GetTop());
	self.TopPercent=Turbine.UI.Label();
	self.TopPercent:SetParent(self.ResponsePanel);
	self.TopPercent:SetSize(40,20);
	self.TopPercent:SetPosition(self.TopText:GetLeft()+self.TopText:GetWidth()+2,self.TopCaption:GetTop());
	self.TopPercent:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.TopPercent:SetText("");

	self.WidthCaption=Turbine.UI.Label();
	self.WidthCaption:SetParent(self.ResponsePanel);
	self.WidthCaption:SetSize(100,20);
	self.WidthCaption:SetPosition(10,self.LeftCaption:GetTop()+25);
	self.WidthCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.WidthCaption:SetText(Resource[language][48]..":");
	self.WidthText=Turbine.UI.Lotro.TextBox();
	self.WidthText:SetParent(self.ResponsePanel);
	self.WidthText:SetSize(80,20);
	self.WidthText:SetFont(fontFace);
	self.WidthText:SetPosition(self.WidthCaption:GetLeft()+self.WidthCaption:GetWidth()+2,self.WidthCaption:GetTop());
	self.WidthPercent=Turbine.UI.Label();
	self.WidthPercent:SetParent(self.ResponsePanel);
	self.WidthPercent:SetSize(40,20);
	self.WidthPercent:SetPosition(self.WidthText:GetLeft()+self.WidthText:GetWidth()+2,self.WidthCaption:GetTop());
	self.WidthPercent:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.WidthPercent:SetText("");

	self.HeightCaption=Turbine.UI.Label();
	self.HeightCaption:SetParent(self.ResponsePanel);
	self.HeightCaption:SetSize(100,20);
	self.HeightCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.LeftCaption:GetTop()+25);
	self.HeightCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.HeightCaption:SetText(Resource[language][49]..":");
	self.HeightText=Turbine.UI.Lotro.TextBox();
	self.HeightText:SetParent(self.ResponsePanel);
	self.HeightText:SetSize(80,20);
	self.HeightText:SetFont(fontFace);
	self.HeightText:SetPosition(self.HeightCaption:GetLeft()+self.HeightCaption:GetWidth()+2,self.HeightCaption:GetTop());
	self.HeightPercent=Turbine.UI.Label();
	self.HeightPercent:SetParent(self.ResponsePanel);
	self.HeightPercent:SetSize(40,20);
	self.HeightPercent:SetPosition(self.HeightText:GetLeft()+self.HeightText:GetWidth()+2,self.HeightCaption:GetTop());
	self.HeightPercent:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.HeightPercent:SetText("");

	self.TopText.Update=function(sender,args)
		local val=tonumber(self.LeftText:GetText());
		if val==nil then
			self.LeftPercent:SetText("");
			alertTemplate:SetLeft(0);
		else
			self.LeftPercent:SetText(tostring(math.floor(val/displayWidth*1000+.5)/10).."%")
			alertTemplate:SetLeft(val);
		end
		val=tonumber(self.TopText:GetText());
		if val==nil then
			self.TopPercent:SetText("");
			alertTemplate:SetTop(0);
		else
			self.TopPercent:SetText(tostring(math.floor(val/displayHeight*1000+.5)/10).."%")
			alertTemplate:SetTop(val);
		end
		val=tonumber(self.WidthText:GetText());
		if val==nil then
			self.WidthPercent:SetText("");
			alertTemplate:SetWidth(displayWidth-alertTemplate:GetLeft());
		else
			self.WidthPercent:SetText(tostring(math.floor(val/displayWidth*1000+.5)/10).."%")
			alertTemplate:SetWidth(val);
		end
		val=tonumber(self.HeightText:GetText());
		if val==nil then
			self.HeightPercent:SetText("");
			alertTemplate:SetHeight(displayHeight-alertTemplate:GetTop());
		else
			self.HeightPercent:SetText(tostring(math.floor(val/displayHeight*1000+.5)/10).."%")
			alertTemplate:SetHeight(val);
		end
		alertTemplate:SetWidth(self.WidthText:GetText());

	end
	self.TopText.FocusGained=function()
		self.TopText:SetWantsUpdates(true);
	end
	self.TopText.FocusLost=function()
		self.TopText:SetWantsUpdates(false);
	end
	self.LeftText.FocusGained=function()
		self.TopText:SetWantsUpdates(true);
	end
	self.LeftText.FocusLost=function()
		self.TopText:SetWantsUpdates(false);
	end
	self.WidthText.FocusGained=function()
		self.TopText:SetWantsUpdates(true);
	end
	self.WidthText.FocusLost=function()
		self.TopText:SetWantsUpdates(false);
	end
	self.HeightText.FocusGained=function()
		self.TopText:SetWantsUpdates(true);
	end
	self.HeightText.FocusLost=function()
		self.TopText:SetWantsUpdates(false);
	end

	self.ColorCaption=Turbine.UI.Label();
	self.ColorCaption:SetParent(self.ResponsePanel);
	self.ColorCaption:SetSize(100,20);
	self.ColorCaption:SetPosition(10,self.WidthCaption:GetTop()+25);
	self.ColorCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.ColorCaption:SetText(Resource[language][7]..":");
	self.MessageColor=ColorPicker();
	self.MessageColor:SetParent(self.ResponsePanel);
	self.MessageColor:SetPosition(self.ColorCaption:GetLeft()+self.ColorCaption:GetWidth()+2,self.ColorCaption:GetTop()-1);
	self.MessageColor:SetTrimColor(Turbine.UI.Color(.4,.4,.4));
	self.MessageColor:SetColor(Turbine.UI.Color(1,0,0));
	self.MessageColor:SetWidth(self.ResponsePanel:GetWidth()/2-self.MessageColor:GetLeft()-12)

	self.FontCaption=Turbine.UI.Label();
	self.FontCaption:SetParent(self.ResponsePanel);
	self.FontCaption:SetSize(100,30);
	self.FontCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.ColorCaption:GetTop()-5);
	self.FontCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.FontCaption:SetText(Resource[language][8]..":");
	self.FontSelect=DropDownList();
	self.FontSelect:SetParent(self.ResponsePanel);
	self.FontSelect:SetPosition(self.FontCaption:GetLeft()+self.FontCaption:GetWidth()+2,self.FontCaption:GetTop()+5);
	self.FontSelect:SetSize(self.ResponsePanel:GetWidth()-self.FontSelect:GetLeft()-10,20);
	self.FontSelect:SetBorderColor(trimColor);
	self.FontSelect:SetBackColor(backColor);
	self.FontSelect.CurrentValue:SetBackColor(backColor);
 	self.FontSelect:SetTextColor(listTextColor);
	self.FontSelect:SetDropRows(3);
	self.FontSelect:SetZOrder(1);
	self.FontSelect.SelectedIndexChanged=function()
	end

	local item=1
	local fontList={}
	for k,v in pairs(Turbine.UI.Lotro.Font) do
		if Turbine.UI.Lotro.FontInfo[v]~=nil then
			table.insert(fontList,{Turbine.UI.Lotro.FontInfo[v].name,Turbine.UI.Lotro.FontInfo[v].size,v})
		end
	end
	table.sort(fontList,function(arg1,arg2) if arg1[1]<arg2[1] then return true else if arg1[1]==arg2[1] and arg1[2]<arg2[2] then return true end end end)
	for k,v in ipairs(fontList) do
		self.FontSelect:AddItem("["..tostring(v[2]).."] "..v[1],v[3]);
		local tmpItem=self.FontSelect.ListData:GetItem(item)
		tmpItem:SetHeight(v[2])
		tmpItem:SetFont(v[3])
		tmpItem:SetText(tmpItem:GetText());
		item=item+1
	end
	self.FontSelect:SetSelectedIndex(24); -- default to the largest

	self.OpacityCaption=Turbine.UI.Label();
	self.OpacityCaption:SetParent(self.ResponsePanel);
	self.OpacityCaption:SetSize(100,20);
	self.OpacityCaption:SetPosition(10,self.ColorCaption:GetTop()+25);
	self.OpacityCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.OpacityCaption:SetText(Resource[language][66]..":");
	self.OpacityValue=Turbine.UI.Lotro.ScrollBar();
	self.OpacityValue:SetParent(self.ResponsePanel);
	self.OpacityValue:SetSize(self.ResponsePanel:GetWidth()/2-self.OpacityCaption:GetLeft()-self.OpacityCaption:GetWidth()-12,10);
	self.OpacityValue:SetPosition(self.OpacityCaption:GetLeft()+self.OpacityCaption:GetWidth()+2,self.OpacityCaption:GetTop()+5);
	self.OpacityValue:SetOrientation(Turbine.UI.Orientation.Horizontal);
	self.OpacityValue:SetMinimum(0);
	self.OpacityValue:SetMaximum(100);
	self.OpacityValue:SetValue(60);
	self.OpacityValue:SetBackColor(Turbine.UI.Color(.2,.1,.1));

	self.ImageCaption=Turbine.UI.Label();
	self.ImageCaption:SetParent(self.ResponsePanel);
	self.ImageCaption:SetSize(100,20);
	self.ImageCaption:SetPosition(self.ResponsePanel:GetWidth()/2,self.OpacityCaption:GetTop());
	self.ImageCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.ImageCaption:SetText(Resource[language][50]..":");
	self.ImageText=Turbine.UI.Lotro.TextBox();
	self.ImageText:SetParent(self.ResponsePanel);
	self.ImageText:SetSize(self.ResponsePanel:GetWidth()-self.ImageCaption:GetLeft()-self.ImageCaption:GetWidth()-12,20);
	self.ImageText:SetFont(fontFace);
	self.ImageText:SetPosition(self.ImageCaption:GetLeft()+self.ImageCaption:GetWidth()+2,self.ImageCaption:GetTop());

	self.UseScrollingText=Turbine.UI.Lotro.CheckBox();
	self.UseScrollingText:SetParent(self.ResponsePanel);
	self.UseScrollingText:SetSize(200,20);
	self.UseScrollingText:SetPosition(self.OpacityValue:GetLeft(),self.OpacityCaption:GetTop()+25);
	self.UseScrollingText:SetSize(self.ResponsePanel:GetWidth()-self.UseScrollingText:GetLeft()-10,20);
	self.UseScrollingText:SetText(Resource[language][68]);

	self.QSCaption=Turbine.UI.Label();
	self.QSCaption:SetParent(self.ResponsePanel);
	self.QSCaption:SetSize(100,40);
	self.QSCaption:SetPosition(10,self.UseScrollingText:GetTop()+25);
	self.QSCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.QSCaption:SetText(Resource[language][60]..":");
	self.QSData=Turbine.UI.Lotro.TextBox();
	self.QSData:SetParent(self.ResponsePanel);
	self.QSData:SetSize(self.ResponsePanel:GetWidth()-64-self.QSCaption:GetWidth()-self.QSCaption:GetLeft(),20);
	self.QSData:SetFont(fontFace);
	self.QSData.OldText="";
	self.QSData:SetPosition(self.QSCaption:GetLeft()+self.QSCaption:GetWidth()+2,self.QSCaption:GetTop());
	self.QSButtons=RadioButtonGroup();
	self.QSButtons:SetParent(self.ResponsePanel);
	self.QSButtons:SetBackColor(self.ResponsePanel:GetBackColor());
	self.QSButtons:SetBorderColor(self.ResponsePanel:GetBackColor());
	self.QSButtons:SetSize(self.ResponsePanel:GetWidth()-125-self.QSData:GetLeft(),20);
	self.QSButtons:SetPosition(self.QSData:GetLeft(),self.QSCaption:GetTop()+25);
	self.QSButtons.UnselectedIcon=resourcePath.."RB_unselected.tga";
	self.QSButtons.SelectedIcon=resourcePath.."RB_selected.tga";
	self.QSButtons.IconWidth=16;
	self.QSButtons.IconHeight=16;
	self.QSButtons:AddChoice(Resource[language][61],1,1);
	self.QSButtons:AddChoice(Resource[language][62],2,2);
	self.QSButtons:AddChoice(Resource[language][63],3,3);
	self.QSButtons:AddChoice(Resource[language][64],4,4);
	self.QSButtons:AddChoice(Resource[language][87],5,5);
	self.QSButtons:AddChoice(Resource[language][88],6,6);
	self.QSButtons:AddChoice(Resource[language][89],7,7);
	self.QSButtons:SetRows(1);
	self.QSButtons:SetSelectedChoice(1);
	self.QSMask=Turbine.UI.Lotro.CheckBox();
	self.QSMask:SetParent(self.ResponsePanel);
	self.QSMask:SetSize(80,20);
	self.QSMask:SetPosition(self.QSButtons:GetLeft(),self.QSButtons:GetTop()+self.QSButtons:GetHeight()+5);
	self.QSMask:SetText(Resource[language][65]);
	self.QSHideAfterClick=Turbine.UI.Lotro.CheckBox()
	self.QSHideAfterClick:SetParent(self.ResponsePanel)
	self.QSHideAfterClick:SetSize(200,20)
	self.QSHideAfterClick:SetPosition(self.QSMask:GetLeft()+self.QSMask:GetWidth(),self.QSMask:GetTop())
	self.QSHideAfterClick:SetText(Resource[language][86])
	self.QSlotBack=Turbine.UI.Control();
	self.QSlotBack:SetParent(self.ResponsePanel);
	self.QSlotBack:SetSize(36,36);
	self.QSlotBack:SetPosition(self.ResponsePanel:GetWidth()-43,self.QSCaption:GetTop()+4)
	self.QSlotBack:SetBackColor(Turbine.UI.Color(.5,.5,1));
	self.QSlot=Turbine.UI.Lotro.Quickslot();
	self.QSlot:SetParent(self.QSlotBack);
	self.QSlot:SetSize(35,35);
	self.QSlot:SetPosition(-1,-1);
	self.DroppingSC=false
	self.QSButtons.SelectionChanged=function()
		if not self.DroppingSC then
			-- try to set the quickslot based on the selected type and the Message text
			local sc=Turbine.UI.Lotro.Shortcut();
			local type=self.QSButtons:GetSelectedChoice();
			local data=self.QSData:GetText();
			if type==4 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Alias);
				sc:SetData(data);
			elseif type==5 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Emote);
				sc:SetData(data);
			elseif type==6 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Pet);
				sc:SetData(data);
			elseif type==7 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Hobby);
				sc:SetData(data);
			elseif type==3 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Skill);
				sc:SetData(data);
			elseif type==2 then
				sc:SetType(Turbine.UI.Lotro.ShortcutType.Item);
				sc:SetData(data);
			else
			end
			local success, result=pcall(Turbine.UI.Lotro.Quickslot.SetShortcut,self.QSlot,sc)
			if not success then
				sc:SetData("0");
				success, result=pcall(Turbine.UI.Lotro.Quickslot.SetShortcut,self.QSlot,sc)
			end
		end
	end
	self.QSlot.DragDrop=function(sender, args)
		self.DroppingSC=true;
		local sc=args.DragDropInfo:GetShortcut();
		local scType=sc:GetType();
		local scData=sc:GetData();
		if scType==Turbine.UI.Lotro.ShortcutType.Alias then
			self.QSButtons:SetSelectedChoice(4);
			self.QSData:SetText(scData);
		elseif scType==Turbine.UI.Lotro.ShortcutType.Emote then
			self.QSButtons:SetSelectedChoice(5);
			self.QSData:SetText(scData);
		elseif scType==Turbine.UI.Lotro.ShortcutType.Pet then
			self.QSButtons:SetSelectedChoice(6);
			self.QSData:SetText(scData);
		elseif scType==Turbine.UI.Lotro.ShortcutType.Hobby then
			self.QSButtons:SetSelectedChoice(7);
			self.QSData:SetText(scData);
		elseif scType==Turbine.UI.Lotro.ShortcutType.Skill then
			self.QSButtons:SetSelectedChoice(3);
			self.QSData:SetText(scData);
		elseif scType==Turbine.UI.Lotro.ShortcutType.Item then
			self.QSButtons:SetSelectedChoice(2);
			self.QSData:SetText(scData);
		else
			self.QSButtons:SetSelectedChoice(1);
			self.QSData:SetText(scData);
		end
		self.DroppingSC=false;
	end
	self.QSData.FocusGained=function()
		self.QSData.OldText=self.QSData:GetText();
		self.QSData:SetWantsUpdates(true);
	end
	self.QSData.FocusLost=function()
		self.QSData:SetWantsUpdates(false);
	end
	self.QSData.Update=function()
		local text=self.QSData:GetText();
		if text~=self.QSData.OldText then
			self.QSButtons.SelectionChanged();
			self.QSData.OldText=text;
		end
	end

-- State section
	self.StateCaption=Turbine.UI.Label();
	self.StateCaption:SetParent(self.TriggerPanel);
	self.StateCaption:SetSize(100,20);
	self.StateCaption:SetPosition(10,5);
	self.StateCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.StateCaption:SetText(Resource[language][82]..":");
	self.StateList=DropDownList();
	self.StateList:SetParent(self.TriggerPanel);
	self.StateList:SetPosition(self.StateCaption:GetLeft()+self.StateCaption:GetWidth()+2,self.StateCaption:GetTop()-1);
	self.StateList:SetSize(150,20);
	self.StateList:SetFont(Turbine.UI.Lotro.Font.Verdana16);
	self.StateList:SetBorderColor(trimColor);
	self.StateList:SetBackColor(backColor);
	self.StateList.CurrentValue:SetBackColor(backColor);
 	self.StateList:SetTextColor(listTextColor);
	self.StateList:SetDropRows(3);
	self.StateList:SetZOrder(2);

	self.StateList:AddItem(Resource[language][76],2) -- out of combat
	self.StateList:AddItem(Resource[language][75],1) -- in combat

	self.StateList.SelectedIndexChanged = function()
		state=self.StateList:GetValue();
		local found=false;
		if States~=nil and #States>0 then
			-- we have states for this alert
			local tmpState;
			for tmpState=1,#States do
				if States[tmpState][1]==state then
					self.StateResponse:SetSelectedChoice(States[tmpState][2]);
					found=true;
					break;
				end
			end
		end
		if not found then
			self.StateResponse:SetSelectedChoice(1);
		end
	end

	-- state response
	self.StateResponse=RadioButtonGroup();
	self.StateResponse:SetParent(self.TriggerPanel);
	self.StateResponse:SetBackColor(self.TriggerPanel:GetBackColor());
	self.StateResponse:SetBorderColor(self.TriggerPanel:GetBackColor());
	self.StateResponse:SetSize(self.TriggerPanel:GetWidth()-30-self.StateList:GetLeft()-self.StateList:GetWidth(),20);
	self.StateResponse:SetPosition(self.StateList:GetLeft()+self.StateList:GetWidth()+10,self.StateCaption:GetTop());
	self.StateResponse.UnselectedIcon=resourcePath.."RB_unselected.tga";
	self.StateResponse.SelectedIcon=resourcePath.."RB_selected.tga";
	self.StateResponse.IconWidth=16;
	self.StateResponse.IconHeight=16;
	self.StateResponse:AddChoice(Resource[language][77],1,1); -- same as nil (we only save the values that are 2 or 3 so that we have less to compare when checking states)
	self.StateResponse:AddChoice(Resource[language][78],2,2); -- delay
	self.StateResponse:AddChoice(Resource[language][79],3,3); -- suppress
	self.StateResponse:SetRows(1);
	self.StateResponse:SetSelectedChoice(1);
	self.StateResponse.SelectionChanged=function()
		state=self.StateList:GetValue();
		newValue=self.StateResponse:GetValue();
		local tmpState;
		local found=false;
		for tmpState=1,#States do
			if States[tmpState][1]==state then
				if newValue==1 then
					table.remove(States,tmpState);
				else
					States[tmpState][2]=newValue;
				end
				found=true;
				break;
			end
		end
		if not found and newValue>1 then
			table.insert(States,{state,newValue});
		end
	end

	self.ChannelCaption=Turbine.UI.Label();
	self.ChannelCaption:SetParent(self.TriggerPanel);
	self.ChannelCaption:SetSize(self.TriggerPanel:GetWidth()-20,20);
	self.ChannelCaption:SetPosition(10,self.StateCaption:GetTop()+25);
	self.ChannelCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.ChannelCaption:SetText(Resource[language][12]);

	local offset=(self.TriggerPanel:GetWidth()-20)/5;
	self.ChannelSelect={};
	ChatChannel={};
	table.insert(ChatChannel,{14,0});
	table.insert(ChatChannel,{15,Turbine.ChatType.Admin});
	table.insert(ChatChannel,{16,Turbine.ChatType.Advancement});
	table.insert(ChatChannel,{17,Turbine.ChatType.Advice});
	table.insert(ChatChannel,{19,Turbine.ChatType.Death});
	table.insert(ChatChannel,{20,Turbine.ChatType.Emote});
	table.insert(ChatChannel,{21,Turbine.ChatType.Error});
	table.insert(ChatChannel,{22,Turbine.ChatType.Fellowship});
	table.insert(ChatChannel,{23,Turbine.ChatType.Kinship});
	table.insert(ChatChannel,{24,Turbine.ChatType.LFF});
	table.insert(ChatChannel,{25,Turbine.ChatType.Officer});
	table.insert(ChatChannel,{26,Turbine.ChatType.OOC});
	table.insert(ChatChannel,{27,Turbine.ChatType.Quest});
	table.insert(ChatChannel,{28,Turbine.ChatType.Raid});
	table.insert(ChatChannel,{29,Turbine.ChatType.Regional});
	table.insert(ChatChannel,{30,Turbine.ChatType.Roleplay});
	table.insert(ChatChannel,{31,Turbine.ChatType.Say});
	table.insert(ChatChannel,{71,Turbine.ChatType.EnemyCombat}); -- Combat Enemy
	table.insert(ChatChannel,{72,Turbine.ChatType.PlayerCombat}); -- Combat Player
	table.insert(ChatChannel,{32,Turbine.ChatType.Standard});
	table.insert(ChatChannel,{55,16777280}); -- Emote Act
	table.insert(ChatChannel,{33,Turbine.ChatType.Tell});
	table.insert(ChatChannel,{34,Turbine.ChatType.Trade});
	table.insert(ChatChannel,{35,Turbine.ChatType.Tribe});
	table.insert(ChatChannel,{36,Turbine.ChatType.Unfiltered});
	table.insert(ChatChannel,{37,Turbine.ChatType.UserChat1});
	table.insert(ChatChannel,{54,16777232}); -- NPC Spew
	table.insert(ChatChannel,{38,Turbine.ChatType.UserChat2});
	table.insert(ChatChannel,{39,Turbine.ChatType.UserChat3});
	table.insert(ChatChannel,{40,Turbine.ChatType.UserChat4});
	table.insert(ChatChannel,{83,36}); -- local loot
	table.insert(ChatChannel,{84,37}); -- group loot
	table.insert(ChatChannel,{73,24}); -- World Broadcast
	table.insert(ChatChannel,{85,38}); -- World chat

	local row=1;
	local col=0;
	for tmpIndex=1,#ChatChannel do
		self.ChannelSelect[tmpIndex]=Turbine.UI.Lotro.CheckBox();
		self.ChannelSelect[tmpIndex]:SetParent(self.TriggerPanel);
		self.ChannelSelect[tmpIndex]:SetSize(offset-10,20);
		self.ChannelSelect[tmpIndex]:SetPosition(offset*col+10,self.ChannelCaption:GetTop()+22*row);
		col=col+1;
		if col>4 then
			col=0;
			row=row+1;
		end
	end

	self.LayoutChannelSelect=function()
		local tmpIndex;
		-- sort the ChatChannel array by text value so we can alphabetize them for the current language
		table.sort(ChatChannel,function(arg1,arg2) if Resource[language][arg1[1]]<Resource[language][arg2[1]] then return(true) end end);
		for tmpIndex=1,#ChatChannel do
			self.ChannelSelect[tmpIndex]:SetText(Resource[language][ChatChannel[tmpIndex][1]]);
			self.ChannelSelect[tmpIndex].Value=ChatChannel[tmpIndex][2];
		end
	end
	self.LayoutChannelSelect();

	self.CustChanCaption=Turbine.UI.Label();
	self.CustChanCaption:SetParent(self.TriggerPanel);
	self.CustChanCaption:SetSize(120,20);
	self.CustChanCaption:SetPosition(10,self.ChannelCaption:GetTop()+row*22+25);
	self.CustChanCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.CustChanCaption:SetText(Resource[language][56]..":");
	self.CustChanText=Turbine.UI.Lotro.TextBox();
	self.CustChanText:SetParent(self.TriggerPanel);
	self.CustChanText:SetSize(100,20);
	self.CustChanText:SetMultiline(false)
	self.CustChanText:SetFont(fontFace);
	self.CustChanText:SetPosition(self.CustChanCaption:GetLeft()+self.CustChanCaption:GetWidth()+2,self.CustChanCaption:GetTop());

	self.PatternCaption=Turbine.UI.Label();
	self.PatternCaption:SetParent(self.TriggerPanel);
	self.PatternCaption:SetSize(100,20);
	self.PatternCaption:SetPosition(10,self.CustChanCaption:GetTop()+25);
	self.PatternCaption:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft);
	self.PatternCaption:SetText(Resource[language][13]..":");
	self.PatternText=Turbine.UI.Lotro.TextBox();
	self.PatternText:SetParent(self.TriggerPanel);
	self.PatternText:SetSize(self.TriggerPanel:GetWidth()-self.PatternCaption:GetLeft()-self.PatternCaption:GetWidth()-12,20);
	self.PatternText:SetFont(fontFace);
	self.PatternText:SetMultiline(false)
	self.PatternText:SetPosition(self.PatternCaption:GetLeft()+self.PatternCaption:GetWidth()+2,self.PatternCaption:GetTop());
--*** Custom Lua stuff
	-- note, separate sub panels are only required due to a bug in the vertical scrollbars that only allow one vertical scrollbar per parent panel
	self.LuaPanelTrigger=Turbine.UI.Control()
	self.LuaPanelTrigger:SetParent(self.LuaPanel)
	self.LuaPanelTrigger:SetSize(self.LuaPanel:GetWidth(),self.LuaPanel:GetHeight()/2)
	self.LuaPanelResponse=Turbine.UI.Control()
	self.LuaPanelResponse:SetParent(self.LuaPanel)
	self.LuaPanelResponse:SetSize(self.LuaPanel:GetWidth(),self.LuaPanelTrigger:GetHeight())
	self.LuaPanelResponse:SetPosition(0,self.LuaPanel:GetHeight()/2)

	self.TriggerLuaLabel=Turbine.UI.Label()
	self.TriggerLuaLabel:SetParent(self.LuaPanelTrigger)
	self.TriggerLuaLabel:SetSize(100,20)
	self.TriggerLuaLabel:SetPosition(10,5)
	self.TriggerLuaLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.TriggerLuaLabel:SetText(Resource[language][93]..":");
	self.TriggerLua=Turbine.UI.Lotro.TextBox()
	self.TriggerLua:SetParent(self.LuaPanelTrigger)
	self.TriggerLua:SetPosition(10,self.TriggerLuaLabel:GetTop()+25)
	self.TriggerLua:SetSize(self.LuaPanel:GetWidth()-30,(self.LuaPanel:GetHeight()-75)/2)

	self.TriggerLuaVScroll=Turbine.UI.Lotro.ScrollBar();
	self.TriggerLuaVScroll:SetOrientation(Turbine.UI.Orientation.Vertical);
	self.TriggerLuaVScroll:SetParent(self.LuaPanelTrigger);
	self.TriggerLuaVScroll:SetBackColor(backColor);
	self.TriggerLuaVScroll:SetPosition(self.TriggerLua:GetWidth()+self.TriggerLua:GetLeft(),self.TriggerLua:GetTop());
	self.TriggerLuaVScroll:SetWidth(10);
	self.TriggerLuaVScroll:SetHeight(self.TriggerLua:GetHeight());
	self.TriggerLuaVScroll:SetVisible(false)
	self.TriggerLua:SetVerticalScrollBar(self.TriggerLuaVScroll);

	self.ResponseLuaLabel=Turbine.UI.Label()
	self.ResponseLuaLabel:SetParent(self.LuaPanelResponse)
	self.ResponseLuaLabel:SetSize(100,20)
	self.ResponseLuaLabel:SetPosition(10,5)
	self.ResponseLuaLabel:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
	self.ResponseLuaLabel:SetText(Resource[language][94]..":");
	self.ResponseLua=Turbine.UI.Lotro.TextBox()
	self.ResponseLua:SetParent(self.LuaPanelResponse)
	self.ResponseLua:SetPosition(10,self.ResponseLuaLabel:GetTop()+25)
	self.ResponseLua:SetSize(self.TriggerLua:GetWidth(),self.TriggerLua:GetHeight())

	self.ResponseLuaVScroll=Turbine.UI.Lotro.ScrollBar();
	self.ResponseLuaVScroll:SetOrientation(Turbine.UI.Orientation.Vertical);
	self.ResponseLuaVScroll:SetParent(self.LuaPanelResponse);
	self.ResponseLuaVScroll:SetBackColor(backColor);
	self.ResponseLuaVScroll:SetPosition(self.ResponseLua:GetWidth()+self.ResponseLua:GetLeft(),self.ResponseLua:GetTop());
	self.ResponseLuaVScroll:SetWidth(10);
	self.ResponseLuaVScroll:SetHeight(self.ResponseLua:GetHeight());
	self.ResponseLuaVScroll:SetVisible(false)
	self.ResponseLua:SetVerticalScrollBar(self.ResponseLuaVScroll);

	self.SaveButton=Turbine.UI.Lotro.Button();
	self.SaveButton:SetParent(self);
	self.SaveButton:SetSize(150,20);
	self.SaveButton:SetText(Resource[language][41]);
	self.SaveButton:SetPosition(20,self:GetHeight()-45);
	self.SaveButton.MouseClick=function()
		local error=false;
		-- if the alertselect is on New, add the definition to the Alerts, otherwise update the one pointed to by the select list
		local tmpIndex;
		local tmpAlertIndex=self.AlertSelect:GetValue();
		if tmpAlertIndex==0 then
			tmpAlertIndex=#Alerts+1
			-- need to add to the alerts list alphabetically
			self.AlertSelect:AddItem(self.LabelText:GetText(),tmpAlertIndex);
			Alerts[tmpAlertIndex]={};
		else
			-- update the alertSelect label
			self.AlertSelect.CurrentValue:SetText(self.LabelText:GetText());
			self.AlertSelect.ListData:GetItem(self.AlertSelect:GetSelectedIndex()):SetText(self.LabelText:GetText());
		end
		Alerts[tmpAlertIndex][1]=self.LabelText:GetText();
		Alerts[tmpAlertIndex][2]=self.MessageText:GetText();
		Alerts[tmpAlertIndex][3]=tonumber(self.DurationText:GetText());
		Alerts[tmpAlertIndex][4]=self.MessageColor:GetColor();
		Alerts[tmpAlertIndex][5]=self.FontSelect:GetValue();
		Alerts[tmpAlertIndex][6]=tonumber(self.IntervalText:GetText());
		Alerts[tmpAlertIndex][7]={};
		for tmpIndex=1,#self.ChannelSelect do
			if self.ChannelSelect[tmpIndex]:IsChecked() then
				table.insert(Alerts[tmpAlertIndex][7],self.ChannelSelect[tmpIndex].Value);
			end
		end
		Alerts[tmpAlertIndex][8]=self.PatternText:GetText();
		Alerts[tmpAlertIndex][9]=tonumber(self.CooldownText:GetText());
-- convert to percents
		local percent=tonumber(self.LeftText:GetText())
		if percent==nil then percent=0 end
		Alerts[tmpAlertIndex][11]=percent/displayWidth*100;
		percent=tonumber(self.TopText:GetText())
		if percent==nil then percent=0 end
		Alerts[tmpAlertIndex][12]=percent/displayHeight*100;

		percent=tonumber(self.WidthText:GetText())
		if percent==nil then
			Alerts[tmpAlertIndex][13]=100;
		else
			Alerts[tmpAlertIndex][13]=percent/displayWidth*100;
		end
		percent=tonumber(self.HeightText:GetText())
		if percent==nil then
			Alerts[tmpAlertIndex][14]=100;
		else
			Alerts[tmpAlertIndex][14]=percent/displayHeight*100;
		end

		Alerts[tmpAlertIndex][15]=string.trim(self.ImageText:GetText());
		if self.AlertSelect:GetSelectedIndex()==1 then
			self.AlertSelect:SetSelectedIndex(self.AlertSelect.ListData:GetItemCount());
		end
		Alerts[tmpAlertIndex][16]=tonumber(self.CustChanText:GetText());
		Alerts[tmpAlertIndex][17]=self.EnabledCB:IsChecked();
		Alerts[tmpAlertIndex][18]=self.QSData:GetText();
		Alerts[tmpAlertIndex][19]=self.QSButtons:GetSelectedChoice();
		Alerts[tmpAlertIndex][20]=self.QSMask:IsChecked();
		Alerts[tmpAlertIndex][21]=self.OpacityValue:GetValue();
		Alerts[tmpAlertIndex][22]=self.UseMousePosition:IsChecked();
		Alerts[tmpAlertIndex][23]=self.UseScrollingText:IsChecked();
		Alerts[tmpAlertIndex][24]=tonumber(self.DelayText:GetText());
		Alerts[tmpAlertIndex][25]={};
		Alerts[tmpAlertIndex][28]=self.SaveToLog:IsChecked();
		Alerts[tmpAlertIndex][27]=self.SharedCB:IsChecked();
		Alerts[tmpAlertIndex][29]=string.trim(self.TriggerLua:GetText())
		Alerts[tmpAlertIndex][30]=string.trim(self.ResponseLua:GetText())

		local tmpState;
		local deadlock={};
		for tmpState=1,#States do
			if States[tmpState][1]==1 or States[tmpState][1]==2 then
				if deadlock[1]==nil then
					deadlock[1]=1
				else
					deadlock[1]=2;
				end
			end
			Alerts[tmpAlertIndex][25][tmpState]={States[tmpState][1],States[tmpState][2]};
		end
		Alerts[tmpAlertIndex][26]=self.QSHideAfterClick:IsChecked();
		-- check for alerts that can never be displayed
		for tmpState=1,#deadlock do
			if deadlock[tmpState]==2 then
				error=true;
				table.insert(alertMain.AlertDisplays,Flasher());
				local args={}
				args.msg="WARNING: This alert contains conflicting State conditions\n that prevent it from ever displaying."
				args.duration=5
				args.color=Turbine.UI.Color(1,1,1)
				args.interval=0
				alertMain.AlertDisplays[#alertMain.AlertDisplays].SetAlert(args);
				break;
			end
		end
		if not error then
			table.insert(alertMain.AlertDisplays,Flasher());
			local args={}
			args.msg="Alert Saved."
			args.duration=1
			args.color=Turbine.UI.Color(1,1,1)
			args.interval=0
			alertMain.AlertDisplays[#alertMain.AlertDisplays].SetAlert(args);
		end
	end

	self.TestButton=Turbine.UI.Lotro.Button();
	self.TestButton:SetParent(self);
	self.TestButton:SetSize(150,20);
	self.TestButton:SetText(Resource[language][42]);
	self.TestButton:SetPosition((self:GetWidth()-40-self.TestButton:GetWidth()*5)/4+self.TestButton:GetWidth()+20,self:GetHeight()-45);
	self.TestButton.MouseClick=function()

		local leftPct=tonumber(self.LeftText:GetText());
		if leftPct==nil then leftPct=0 end
		leftPct=leftPct/displayWidth*100;

		local topPct=tonumber(self.TopText:GetText());
		if topPct==nil then topPct=0 end
		topPct=topPct/displayHeight*100;

		local widthPct=tonumber(self.WidthText:GetText());
		if widthPct==nil then
			widthPct=100;
		else
			widthPct=widthPct/displayWidth*100;
		end
		local heightPct=tonumber(self.HeightText:GetText());
		if heightPct==nil then
			heightPct=100;
		else
			heightPct=heightPct/displayHeight*100;
		end
		local delayTime=tonumber(self.DelayText:GetText());
		table.insert(self.AlertDisplays,Flasher());
		local args={}
		if self.MessageText:GetText()=="" then
			args.msg=self.PatternText:GetText()
		else
			args.msg=self.MessageText:GetText()
		end
		args.duration=tonumber(self.DurationText:GetText())
		args.color=self.MessageColor:GetColor()
		args.font=self.FontSelect:GetValue()
		args.interval=tonumber(self.IntervalText:GetText())
		args.left=tonumber(leftPct)
		args.top=tonumber(topPct)
		args.width=tonumber(widthPct)
		args.height=tonumber(heightPct)
		args.image=self.ImageText:GetText()
		args.qsType=self.QSButtons:GetSelectedChoice()
		args.qsData=self.QSData:GetText()
		args.qsMask=self.QSMask:IsChecked()
		args.opacity=self.OpacityValue:GetValue()
		args.useMousePosition=self.UseMousePosition:IsChecked()
		args.scroll=self.UseScrollingText:IsChecked()
		args.delay=delayTime
		args.qsHideAfterClick=self.QSHideAfterClick:IsChecked()
		args.saveToLog=self.SaveToLog:IsChecked()
		args.responseLua=self.ResponseLua:GetText()
		self.AlertDisplays[#self.AlertDisplays].SetAlert(args);
	end

	self.ChatLogButton=Turbine.UI.Lotro.Button();
	self.ChatLogButton:SetParent(self);
	self.ChatLogButton:SetSize(150,20);
	self.ChatLogButton:SetText(Resource[language][53]);
	self.ChatLogButton:SetPosition((self:GetWidth()-40-self.ChatLogButton:GetWidth()*5)*2/4+self.ChatLogButton:GetWidth()*2+20,self:GetHeight()-45);
	self.ChatLogButton.MouseClick=function()
		alertLog:SetVisible(true);
	end

	self.AlertLogButton=Turbine.UI.Lotro.Button();
	self.AlertLogButton:SetParent(self);
	self.AlertLogButton:SetSize(150,20);
	self.AlertLogButton:SetText(Resource[language][95]);
	self.AlertLogButton:SetPosition((self:GetWidth()-40-self.AlertLogButton:GetWidth()*5)*3/4+self.AlertLogButton:GetWidth()*3+20,self:GetHeight()-45);
	self.AlertLogButton.MouseClick=function()
		logViewer:SetVisible(true);
	end

	self.DeleteButton=Turbine.UI.Lotro.Button();
	self.DeleteButton:SetParent(self);
	self.DeleteButton:SetSize(150,20);
	self.DeleteButton:SetText(Resource[language][43]);
	self.DeleteButton:SetPosition(self:GetWidth()-self.DeleteButton:GetWidth()-20,self:GetHeight()-45);
	self.DeleteButton.MouseClick=function()
		local tmpListIndex=self.AlertSelect:GetSelectedIndex();
		if tmpListIndex>1 then
			local tmpAlertIndex=self.AlertSelect:GetValue();
			local tmpIndex, tmpLabel;
			tmpLabel=Alerts[tmpAlertIndex][2];
			table.remove(Alerts,tmpAlertIndex);
			for tmpIndex=1,self.AlertSelect.ListData:GetItemCount() do
				if self.AlertSelect.ListData:GetItem(tmpIndex).DataValue>tmpAlertIndex then
					self.AlertSelect.ListData:GetItem(tmpIndex).DataValue=self.AlertSelect.ListData:GetItem(tmpIndex).DataValue-1;
				end
			end
			self.AlertSelect:RemoveItemAt(tmpListIndex);
			self.AlertSelect:SetSelectedIndex(1);
			if tmpListIndex>self.AlertSelect.ListData:GetItemCount() then
				self.AlertSelect:SetSelectedIndex(self.AlertSelect.ListData:GetItemCount());
			else
				self.AlertSelect:SetSelectedIndex(tmpListIndex);
			end
			-- flash deleted message
			table.insert(alertMain.AlertDisplays,Flasher());
			local args={}
			args.msg="Alert: "..tmpLabel.." DELETED"
			args.duration=1
			args.color=Turbine.UI.Color(1,1,1)
			args.interval=0
			alertMain.AlertDisplays[#alertMain.AlertDisplays].SetAlert(args);
		end
	end

	self.KeyDown=function(sender, args)
		if ( args.Action == Turbine.UI.Lotro.Action.Escape ) then
			self:SetVisible(false);
			alertTemplate:SetVisible(false);
			alertLog:SetVisible(false);
			logViewer:SetVisible(false);
			if debugWindow~=nil then
				debugWindow:SetVisible(false)
			end
		end
		if ( args.Action == 268435635 ) then -- toggle HUD
			alertHUDState = not alertHUDState;
			if alertHUDState then
				alertMain:SetVisible(alertMainState);
				alertTemplate:SetVisible(alertMainState);
				alertLog:SetVisible(alertLogState);
				logViewer:SetVisible(logViewerState)
			else
				alertMainState=alertMain:IsVisible();
				alertLogState=alertLog:IsVisible();
				logViewerState=logViewer:IsVisible()
				alertMain:SetVisible(false);
				alertTemplate:SetVisible(false);
				alertLog:SetVisible(false);
				logViewer:SetVisible(false)
			end
		end
	end
	self.loaded=false;
	self:SetWantsUpdates(true);
	self.Update=function()
		if not self.loaded then
			self.loaded=true;
			Plugins["Alerter"].Unload = function(self,sender,args)
				UnloadPlugin();
			end
			self:SetWantsUpdates(false);
			Turbine.Shell.WriteLine("Alerter "..Plugins["Alerter"]:GetVersion().." by Garan loaded");
		else
			self:SetWantsUpdates(false);
			local alertIndex=1;
			while alertIndex<=#self.AlertDisplays do
				if self.AlertDisplays[alertIndex].Done then
					-- recycle any alert that is flagged as Done
					table.remove(self.AlertDisplays,alertIndex);
				else
					alertIndex=alertIndex+1;
				end
			end
			if #self.AlertDisplays==0 then
				alertTemplate:SetVisible(alertMain:IsVisible());
			end
		end
	end

	self.RemoveShellCommands=function(sender,args)
		Turbine.Shell.RemoveCommand(self.shellCmd)
	end

	self.shellCmd=Turbine.ShellCommand();
	local numberOfCommandsRegistered = Turbine.Shell.AddCommand("Alerter",self.shellCmd);

	self.shellCmd.Execute = function(sender, cmd, args)
		if (string.lower(cmd) == "alerter") then
			local pos1=string.find(args," ",0,true);
			local command;
			if pos1~=nil and pos1>0 then
				command=string.lower(string.sub(args,1,pos1-1));
			else
				command=string.lower(args);
			end
			if (command=="setup") then
				self:SetVisible(true);
				alertTemplate:SetVisible(true);
			elseif (string.lower(args)=="log start") then
				logChat=true;
				alertLog.StartButton:SetText(Resource[language][58]);
			elseif (string.lower(args)=="log stop") then
				logChat=false;
				alertLog.StartButton:SetText(Resource[language][57]);
			elseif (string.lower(args)=="log show") then
				alertLog:SetVisible(true);
			elseif (string.lower(args)=="debug") then
				if debugWindow~=nil then
					debugWindow:SetVisible(true)
				end
			else
				Turbine.Shell.WriteLine("usage:");
				Turbine.Shell.WriteLine("  /Alerter setup");
				Turbine.Shell.WriteLine("       Displays the Alerter Setup window.");
				Turbine.Shell.WriteLine("  /Alerter Log (start|stop|show)");
				Turbine.Shell.WriteLine("       Starts, Stops or Displays the Alerter Chat Log window.");
			end
		end
	end
	self.shellCmd.GetHelp = function(sender, cmd)
		return("usage:\n  /Alerter setup\n       Displays the Alerter Setup window.");
	end

	self.shellCmd.GetShortHelp = function(sender, cmd)
		return("Alerter - usage: /Alerter setup");
	end
	self:SetWantsKeyEvents(true);
	self.VisibleChanged=function()
		if not self:IsVisible() then
			alertTemplate:SetVisible(false);
		end
	end

	self.alerterReceived=function(sender, args)
		local channelMatched;
		local tmpAlert, tmpChannel;
		if logChat then
			-- add to log
			if alertLog.History:GetItemCount()>1000 then
				alertLog.History:RemoveItemAt(1);
			end
			local tmpRow=Turbine.UI.Control();
			tmpRow:SetParent(alertLog.History);
			tmpRow:SetHeight(14);
			tmpRow:SetWidth(alertLog.History:GetWidth());
			tmpRow.Channel=Turbine.UI.Label();
			tmpRow.Channel:SetParent(tmpRow);
			tmpRow.Channel:SetFont(Turbine.UI.Lotro.Font.Verdana14)
			tmpRow.Channel:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
			tmpRow.Channel:SetText(args.ChatType);
			for tmpIndex=1,#self.ChannelSelect do
				if self.ChannelSelect[tmpIndex].Value==args.ChatType then
					tmpRow.Channel:SetText(self.ChannelSelect[tmpIndex]:GetText());
					break;
				end
			end
			tmpRow.Channel:SetSize(120,14);
			tmpRow.Channel:SetPosition(0,0);
			tmpRow.Sender=Turbine.UI.Label();
			tmpRow.Sender:SetParent(tmpRow);
			tmpRow.Sender:SetSize(100,14);
			tmpRow.Sender:SetPosition(120,0);
			tmpRow.Sender:SetFont(Turbine.UI.Lotro.Font.Verdana14)
			tmpRow.Sender:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)
			tmpRow.Sender:SetText(args.Sender);
			tmpRow.Msg=Turbine.UI.Label();
			tmpRow.Msg:SetParent(tmpRow);
			tmpRow.Msg:SetSize(tmpRow:GetWidth()-220,14);
			alertLog.tmpText:SetSize(tmpRow:GetWidth()-220,14);
			tmpRow.Msg:SetPosition(220,0);
			tmpRow.Msg:SetFont(Turbine.UI.Lotro.Font.Verdana14)
			tmpRow.Msg:SetTextAlignment(Turbine.UI.ContentAlignment.TopLeft)

			-- there's probably a better way to do this, but this substitution prevents the label from processing the xml tags
			tmpRow.Msg:SetText(string.gsub(args.Message,"<","|"));
			alertLog.tmpText:SetText(string.gsub(args.Message,"<","|"))

			-- ExamineItemInstance:ItemInfo tags contain byte data which is being incorrectly translated as characters and is throwing off the chracter positioning
			-- need to explore these bytes and see what they really represent
			-- note that if the original message coincidentally included a pipe character "|" then that character will get switched to a "<" in the log.
			local tmpPos=string.find(args.Message,"<")
			while tmpPos~=nil and tmpPos<=string.len(args.Message) do
				tmpRow.Msg:SetSelection(tmpPos,1)
				alertLog.tmpText:SetSelection(tmpPos,1)
				tmpRow.Msg:SetSelectedText("<")
				alertLog.tmpText:SetSelectedText("<")
				tmpPos=string.find(args.Message,"<",tmpPos+1)
			end

			tmpRow.Msg:SetSelection(0,0);
			tmpRow.Msg:SetSelectable(true);
			alertLog.tmpText:SetHeight(14);
			-- allow the height to autoexpand to 10 rows
			while alertLog.tmpVScroll:IsVisible() and alertLog.tmpText:GetHeight()<140 do
				alertLog.tmpText:SetHeight(alertLog.tmpText:GetHeight()+14);
			end
			tmpRow.Msg:SetHeight(alertLog.tmpText:GetHeight());
			tmpRow:SetHeight(alertLog.tmpText:GetHeight()+1);

			local autoscroll=(alertLog.History:GetItemCount()==0) or (alertLog.History:GetSelectedIndex()==alertLog.History:GetItemCount())

			alertLog.History:AddItem(tmpRow);
			if autoscroll then
				alertLog.History:SetVerticalScrollBar(nil);
				alertLog.History:SetSelectedIndex(alertLog.History:GetItemCount());
				alertLog.History:SetVerticalScrollBar(alertLog.VScroll);
			end
		end
		if args.Message~=nil then
			for tmpIndex=1,#Alerts do
				if (Alerts[tmpIndex][10]==nil or Turbine.Engine:GetGameTime()>=Alerts[tmpIndex][10]) and (Alerts[tmpIndex][17]==nil or Alerts[tmpIndex][17]) then
					channelMatched=false;
					if Alerts[tmpIndex][7]~=nil and type(Alerts[tmpIndex][7])=="table" then
						if Alerts[tmpIndex][16]~=nil and Alerts[tmpIndex][16]==args.ChatType then
							channelMatched=true;
						else
							for tmpAlert=1,#Alerts[tmpIndex][7] do
								if Alerts[tmpIndex][7][tmpAlert]~=nil then
									if Alerts[tmpIndex][7][tmpAlert]==0 or Alerts[tmpIndex][7][tmpAlert]==args.ChatType then
										channelMatched=true;
										break;
									end
								end
							end
						end
					end
					-- channel matched
-- compare to pattern
					if channelMatched then
--						local captures=({string.match(string.lower(args.Message),string.lower(Alerts[tmpIndex][8]))});
						local captures=({string.match(args.Message,Alerts[tmpIndex][8])});
						if Alerts[tmpIndex][8]==nil or #captures>0 then
							StateLevel= GetAlertState(tmpIndex);
							if StateLevel<3 then
-- evaluate trigger Lua
								local success=true
								local result
								if Alerts[tmpIndex][29]~=nil and Alerts[tmpIndex][29]~="" then
									local userFunc,error=loadstring("return function(self,args,captures) "..Alerts[tmpIndex][29].." end");
									if userFunc==nil then
										Turbine.Shell.WriteLine("Error compiling Trigger Lua:"..tostring(error));
										success=false
									else
										success,userFunc=pcall(userFunc)
										setfenv(userFunc,getfenv()); -- we set the environment to the current plugin environment
										local args2={}
										args2.self=self
										args2.Message=args.Message
										args2.Sender=args.Sender
										args2.channel=args.ChatType
										args2.captures=captures
										success,result=pcall(userFunc,args);
										if success then
											if result~=nil and result==false then
												success=false
											end
										else
											Turbine.Shell.WriteLine("Error executing Trigger Lua:"..tostring(result));
										end
									end
								end
								if success then
									local msg;
--									Turbine.Shell.WriteLine("Channel:["..args.ChatType.."] Sender:"..args.Sender.." Message:"..args.Message)
									if Alerts[tmpIndex][2]==nil or Alerts[tmpIndex][2]=="" then
										msg=args.Message
									else
										msg=Alerts[tmpIndex][2]
									end
									if Alerts[tmpIndex][9]~=nil and Alerts[tmpIndex][9]>0 then
										Alerts[tmpIndex][10]=Turbine.Engine:GetGameTime()+Alerts[tmpIndex][9];
									end
									table.insert(alertMain.AlertDisplays,Flasher());
									local args2={}
									args2.index=tmpIndex
									args2.msg=msg
									args2.duration=Alerts[tmpIndex][3]
									args2.color=Alerts[tmpIndex][4]
									args2.font=Alerts[tmpIndex][5]
									args2.interval=Alerts[tmpIndex][6]
									args2.left=Alerts[tmpIndex][11]
									args2.top=Alerts[tmpIndex][12]
									args2.width=Alerts[tmpIndex][13]
									args2.height=Alerts[tmpIndex][14]
									args2.image=Alerts[tmpIndex][15]
									args2.captures=captures
									args2.channel=args.ChatType
									args2.Sender=args.Sender
									args2.Message=args.Message
									args2.qsType=Alerts[tmpIndex][19]
									args2.qsData=Alerts[tmpIndex][18]
									args2.qsMask=Alerts[tmpIndex][20]
									args2.opacity=Alerts[tmpIndex][21]
									args2.useMousePosition=Alerts[tmpIndex][22]
									args2.scroll=Alerts[tmpIndex][23]
									args2.delay=Alerts[tmpIndex][24]
									args2.state=StateLevel
									args2.qsHideAfterClick=Alerts[tmpIndex][26]
									args2.saveToLog=Alerts[tmpIndex][28]
									args2.responseLua=Alerts[tmpIndex][30]
									alertMain.AlertDisplays[#alertMain.AlertDisplays].SetAlert(args2)
								end
							end
						end
					end
				end
			end
		end
	end
	AddCallback(Turbine.Chat, "Received", self.alerterReceived)

	self.SetLanguage=function()
		self:SetText(Resource[language][2])
		self.AlertCaption:SetText(Resource[language][3]..":");
		self.AlertSelect.ListData:GetItem(1):SetText(Resource[language][4]);
		if self.AlertSelect:GetSelectedIndex()==1 then
			self.AlertSelect.CurrentValue:SetText(Resource[language][4]);
		end
		self.LabelCaption:SetText(Resource[language][5]..":");
		self.MessageCaption:SetText(Resource[language][6]..":");
		self.ColorCaption:SetText(Resource[language][7]..":");
		self.FontCaption:SetText(Resource[language][8]..":");
		self.DurationCaption:SetText(Resource[language][9]..":");
		self.IntervalCaption:SetText(Resource[language][10]..":");
		self.ChannelCaption:SetText(Resource[language][12]);
		self.PatternCaption:SetText(Resource[language][13]..":");
		self.LanguageCaption:SetText(Resource[language][44]..":");
		self.CooldownCaption:SetText(Resource[language][45]..":");
		self.LeftCaption:SetText(Resource[language][46]..":");
		self.TopCaption:SetText(Resource[language][47]..":");
		self.WidthCaption:SetText(Resource[language][48]..":");
		self.HeightCaption:SetText(Resource[language][49]..":");
		self.ImageCaption:SetText(Resource[language][50]..":");
		alertLog:SetText(Resource[language][51]);
		alertLog.ClearButton:SetText(Resource[language][52]);
		self.ChatLogButton:SetText(Resource[language][53]);
		self.CustChanCaption:SetText(Resource[language][56]..":");
		if logChat then
			alertLog.StartButton:SetText(Resource[language][58])
		else
			alertLog.StartButton:SetText(Resource[language][57]);
		end
		self.EnabledCB:SetText(Resource[language][59]);
		self.QSCaption:SetText(Resource[language][60]..":");
		self.QSButtons.Choices[1].Caption:SetText(Resource[language][61]);
		self.QSButtons.Choices[2].Caption:SetText(Resource[language][62]);
		self.QSButtons.Choices[3].Caption:SetText(Resource[language][63]);
		self.QSButtons.Choices[4].Caption:SetText(Resource[language][64]);
		self.QSMask:SetText(Resource[language][65]);
		self.QSHideAfterClick:SetText(Resource[language][86])
		self.OpacityCaption:SetText(Resource[language][66]..":");
		self.UseMousePosition:SetText(Resource[language][67]);
		self.SaveToLog:SetText(Resource[language][90]);
		self.SharedCB:SetText(Resource[language][91]);
		self.UseScrollingText:SetText(Resource[language][68]);
		self.TriggerTab:SetText(Resource[language][69]);
		self.ResponseTab:SetText(Resource[language][70]);

		self.SaveButton:SetText(Resource[language][41]);
		self.TestButton:SetText(Resource[language][42]);
		self.DeleteButton:SetText(Resource[language][43]);
		-- record the current channel selections
		local tmpIndex,tmpIndex2;
		local curSel={};
		for tmpIndex=1,#ChatChannel do
			curSel[tmpIndex]={self.ChannelSelect[tmpIndex].Value,self.ChannelSelect[tmpIndex]:IsChecked()};
		end
		-- re-layout the channels
		self.LayoutChannelSelect();
		-- re-assign the checks using curSel
		for tmpIndex=1,#ChatChannel do
			for tmpIndex2=1,#ChatChannel do
				if curSel[tmpIndex2][1]==self.ChannelSelect[tmpIndex].Value then
					self.ChannelSelect[tmpIndex]:SetChecked(curSel[tmpIndex2][2]);
				end
			end
		end
		self.StateList.ListData:GetItem(1):SetText(Resource[language][76]) -- out of combat
		self.StateList.ListData:GetItem(2):SetText(Resource[language][75]) -- in combat
		if self.StateList:GetSelectedIndex()~=nil and self.StateList:GetSelectedIndex()>0 then
			self.StateList.CurrentValue:SetText(self.StateList.ListData:GetItem(self.StateList:GetSelectedIndex()):GetText());
		end
		self.StateResponse.Choices[1].Caption:SetText(Resource[language][77]); -- same as nil (we only save the values that are 2 or 3 so that we have less to compare when checking states)
		self.StateResponse.Choices[2].Caption:SetText(Resource[language][78]); -- delay
		self.StateResponse.Choices[3].Caption:SetText(Resource[language][79]); -- suppress
	end
end
alertMain=Alerter();
