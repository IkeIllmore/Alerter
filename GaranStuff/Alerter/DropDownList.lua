import "Turbine.UI";
import "Turbine.UI.Lotro";
DropDownList = class( Turbine.UI.Control );

function DropDownList:Constructor()
	Turbine.UI.Control.Constructor( self );
	self.TextColor=Turbine.UI.Color(1,1,1);
	self.CurrentValue=Turbine.UI.Label();
	self.CurrentValue:SetParent(self);
	self.CurrentValue:SetPosition(1,1);
	self.CurrentValue:SetHeight(18);
	self.CurrentValue:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	self.CurrentValue:SetFont(Turbine.UI.Lotro.Font.TrajanPro14);
	self.CurrentValue:SetForeColor(self.TextColor);
	self.CurrentValue.DataValue=nil;
	self.DropButtonBack=Turbine.UI.Control();
	self.RowHeight=18; -- the default row height
	self.Font=Turbine.UI.Lotro.Font.TrajanPro14;

	self.DropButtonBack:SetParent(self);
	self.DropButtonBack:SetPosition(0,1);
	self.DropButtonBack:SetSize(15,17);
	self.DropButtonBack:SetBackColor(Turbine.UI.Color(.1,.1,.1));

	self.DropButton=Turbine.UI.Button();
	self.DropButton:SetParent(self.DropButtonBack);
	self.DropButton:SetPosition(0,0);
	self.DropButton:SetSize(15,18);
	self.DropButton:SetBlendMode(Turbine.UI.BlendMode.Overlay);
	self.DropButton:SetBackground(0x41007e1b);
	self.ListData=Turbine.UI.ListBox();
	self.ListData:SetParent(self);
	self.ListData:SetPosition(1,21);
	self.ListData:SetHeight(0);
	self.ListData.SelectedIndexChanged=function()
		if self.ListData:GetSelectedIndex()>0 then
			self.CurrentValue:SetText(self.ListData:GetItem(self.ListData:GetSelectedIndex()):GetText());
			self.DataValue=self.ListData:GetItem(self.ListData:GetSelectedIndex()):GetValue();
		end
	end

	Turbine.UI.Control.SetBackColor(self,Turbine.UI.Color(.5,.5,.1));
	self.ListData.VScrollBar=Turbine.UI.Lotro.ScrollBar();
	self.ListData.VScrollBar:SetOrientation(Turbine.UI.Orientation.Vertical);
	self.ListData.VScrollBar:SetParent(self.ListData);
	self.ListData.VScrollBar:SetBackColor(Turbine.UI.Color(.1,.1,.1));
	self.ListData.VScrollBar:SetWidth(10);
	self.ListData.VScrollBar:SetHeight(0);
	self.DropRows=5;

	self.ListData.FocusLost = function(sender,args)
		self:HideList();
	end

	self.CurrentValue.MouseClick = function(sender,args)
		if (self.ListData:GetHeight()>0) then
			self:HideList();
		else
			self:ShowList();
		end
	end

	self.DropButton.Click = function (sender,args)
		if (self.ListData:GetHeight()>0) then
			self:HideList();
		else
			self:ShowList();
		end
	end

	self.SelectedIndexChanged = function() -- placeholder for the event handler
	end
end

function DropDownList:SetFont(font)
	local fontFound=false;
	if font==Turbine.UI.Lotro.Font.Arial12 then
		self.RowHeight=13;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro13 then
		self.RowHeight=14;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro14 then
		self.RowHeight=15;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro15 then
		self.RowHeight=16;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro16 then
		self.RowHeight=17;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro18 then
		self.RowHeight=19;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro19 then
		self.RowHeight=20;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro20 then
		self.RowHeight=21;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro21 then
		self.RowHeight=22;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro23 then
		self.RowHeight=24;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro24 then
		self.RowHeight=25;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro25 then
		self.RowHeight=26;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro26 then
		self.RowHeight=27;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanPro28 then
		self.RowHeight=29;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold16 then
		self.RowHeight=17;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold22 then
		self.RowHeight=23;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold24 then
		self.RowHeight=25;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold25 then
		self.RowHeight=25;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold30 then
		self.RowHeight=30;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.TrajanProBold36 then
		self.RowHeight=36;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana10 then
		self.RowHeight=11;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana12 then
		self.RowHeight=13;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana14 then
		self.RowHeight=15;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana16 then
		self.RowHeight=17;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana18 then
		self.RowHeight=19;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana20 then
		self.RowHeight=21;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana22 then
		self.RowHeight=23;
		fontFound=true;
	elseif font==Turbine.UI.Lotro.Font.Verdana23 then
		self.RowHeight=24;
		fontFound=true;
	elseif font==0x42000021 then 
		self.RowHeight=13;
		fontFound=true;
	elseif font==0x4200000e then 
		self.RowHeight=21;
		fontFound=true;
	elseif font==0x4200000f then 
		self.RowHeight=23;
		fontFound=true;
	elseif font==0x42000010 then 
		self.RowHeight=25;
		fontFound=true;
	elseif font==0x4200002b then 
		self.RowHeight=15;
		fontFound=true;
	end
--TimesRoman12= 0x42000021
--TimesRoman20= 0x4200000e
--TimesRoman22= 0x4200000f
--TimesRoman24= 0x42000010
--Calibri14= 0x4200002b


	if fontFound then
		self.Font=font
		self.CurrentValue:SetFont(font);
		self.CurrentValue:SetHeight(self.RowHeight);
		local index;
		for index=1,self.ListData:GetItemCount() do
			self.ListData:GetItem(index):SetFont(font);
		end
		if self.ListData:GetHeight()>0 then
			self:ShowList();
		else
			self:SetHeight(self.RowHeight+2);
		end
		self.ListData:SetTop(self.RowHeight+5);
	end
end
function DropDownList:SetEnabled(state)
	self.CurrentValue:SetMouseVisible(state);
	self.DropButton:SetMouseVisible(state);
end

function DropDownList:SetDropRows(rows)
	self.DropRows=rows;
	if (self.ListData:GetHeight()>0) then
		-- redisplay the rows
		self:ShowList();
	end
end

function DropDownList:SetBorderColor( color )
	Turbine.UI.Control.SetBackColor(self,color);
end

function DropDownList:SetTextColor( color )
	self.TextColor=color;
	self.CurrentValue:SetForeColor(color);
	local tmpIndex;
	for tmpIndex=1,self.ListData:GetItemCount() do
		self.ListData:GetItem(tmpIndex):SetForeColor(color);
	end
end

function DropDownList:SizeChanged()
	width=self:GetWidth();
	self.CurrentValue:SetWidth(width-18);
	self.DropButtonBack:SetLeft(width-16);
	self.ListData:SetWidth(width-2);
	if (self.ListData:GetItemCount()>0) then
		for lIndex = 1, self.ListData:GetItemCount() do
			self.ListData:GetItem(lIndex):SetWidth(width-17);
		end
	end
	self.ListData.VScrollBar:SetPosition(width-11,1);
end

function DropDownList:AddItem(text, datavalue)
	local listItem = Turbine.UI.Label();
	listItem:SetMultiline(false);
	listItem:SetSize(self.ListData:GetWidth()-11,self.RowHeight);
	listItem:SetOpacity(self:GetOpacity());
	listItem:SetBackColor(self.ListData:GetBackColor());
	listItem:SetForeColor(self.TextColor);
	listItem:SetTextAlignment( Turbine.UI.ContentAlignment.MiddleLeft );
	listItem:SetFont(self.Font);
	listItem:SetText(text);
	listItem.DataValue=datavalue;
	listItem.isVisible=true;
	listItem.Index=self.ListData:GetItemCount()+1;
	listItem.MouseClick = function (sender, args)
		self.CurrentValue:SetText(listItem:GetText());
		self.CurrentValue.DataValue=listItem.DataValue;
		self:HideList();
		self.ListData:SetSelectedIndex(listItem.Index);
		self:SelectedIndexChanged();
	end
	listItem.GetValue = function (sender)
		return listItem.DataValue;
	end
	self.ListData:AddItem (listItem);
	if (self.ListData:GetItemCount()==1) then
		-- autoselect the newly added item
		self.CurrentValue:SetText(text);
		self.ListData:SetSelectedIndex(listItem.Index);
	end
end

function DropDownList:ClearList()
	while self.ListData:GetItemCount()>0 do
		-- need to eliminate the old event handler
		self.ListData:GetItem(1).MouseClick = nil;
		self.ListData:RemoveItemAt(1);
	end
	self.CurrentValue:SetText("");
	self.CurrentValue.DataValue=0;
end

function DropDownList:RemoveItemAt(index)
	index=tonumber(index)
	local nextIndex;
	if index>0 and index<=self.ListData:GetItemCount() then
		for nextIndex=index+1,self.ListData:GetItemCount() do
			self.ListData:GetItem(nextIndex).Index=self.ListData:GetItem(nextIndex).Index-1;
		end
		nextIndex=self.ListData:GetSelectedIndex();
		-- need to eliminate the old event handler
		self.ListData:GetItem(index).MouseClick = nil;
		self.ListData:RemoveItemAt(index);
		if self.ListData:GetItemCount()>0 then
			if nextIndex>self.ListData:GetItemCount() then
				self.CurrentValue:SetText(self.ListData:GetItem(self.ListData:GetItemCount()):GetText());
				self.ListData:SetSelectedIndex(self.ListData:GetItemCount());
				self:SelectedIndexChanged();
			elseif nextIndex>index then
				self.CurrentValue:SetText(self.ListData:GetItem(nextIndex-1):GetText());
				self.ListData:SetSelectedIndex(nextIndex-1);
				self:SelectedIndexChanged();
			else
				self.CurrentValue:SetText(self.ListData:GetItem(nextIndex):GetText());
				self.ListData:SetSelectedIndex(nextIndex);
				self:SelectedIndexChanged();
			end
		else
			self.CurrentValue:SetText("")
		end
	end
end

function DropDownList:GetValue()
	local dataValue=nil;
	if self.ListData:GetItemCount()>0 then
		dataValue=self.ListData:GetItem(self.ListData:GetSelectedIndex()).DataValue;
	end
	return (dataValue);
end

function DropDownList:GetText()
	return (self.CurrentValue:GetText());
end

function DropDownList:SetCurrentBackColor( color )
	self.CurrentValue:SetBackColor( color );
end

function DropDownList:SetBackColor( color )
local index;
	self.ListData:SetBackColor(color);
	if (self.ListData:GetItemCount()>0) then
		for index = 1,self.ListData:GetItemCount() do
			self.ListData:GetItem(index):SetBackColor( color );
		end
	end
	self.ListData.VScrollBar:SetBackColor(color);
end

function DropDownList:HideEntry(index)
	if index>0 and index<=self.ListData:GetItemCount() then
		self.ListData:GetItem(index).isVisible=false;
		self.ListData:GetItem(index):SetHeight(0);
		if self:GetHeight()>20 then
			self:ShowList()
		end
	end
end

function DropDownList:ShowEntry(index)
	if index>0 and index<=self.ListData:GetItemCount() then
		self.ListData:GetItem(index).isVisible=true;
		self.ListData:GetItem(index):SetHeight(self.RowHeight);
		if self:GetHeight()>20 then
			self:ShowList()
		end
	end
end

function DropDownList:SetSelectedIndex(index)
	if index>0 and index<=self.ListData:GetItemCount() then
		self.ListData:SetSelectedIndex(index);
	end
end
function DropDownList:GetSelectedIndex()
	return self.ListData:GetSelectedIndex();
end

function DropDownList:ShowList()
local visibleRows=0;
local index;
	for index=1,self.ListData:GetItemCount() do
		if self.ListData:GetItem(index).isVisible then
			visibleRows=visibleRows+1;
		end
	end
	if (visibleRows>self.DropRows) then
		self.ListData:SetHeight(self.RowHeight*self.DropRows);
		self.ListData.VScrollBar:SetHeight(self.ListData:GetHeight());
		self.ListData:SetVerticalScrollBar(self.ListData.VScrollBar);
		-- I use this bizarre combination of unbinding and rebinding the scrollbar to eliminate the odd
		-- resizing of the built in thumb button after the scrollbar is displayed the first time (comment out the next two lines to see the weird resizing)
		self.ListData:SetVerticalScrollBar();
		self.ListData:SetVerticalScrollBar(self.ListData.VScrollBar);
	else
		self.ListData:SetHeight(self.RowHeight*visibleRows);
		self.ListData:SetVerticalScrollBar();
	end
	self:SetHeight(self.ListData:GetHeight()+23);
	self.ListData:SetWantsKeyEvents(true);
	self.ListData:SetWantsUpdates(true);
end

function DropDownList:HideList()
	self.ListData:SetHeight(0);
	self.ListData.VScrollBar:SetHeight(0);
	self:SetHeight(self.RowHeight+2);
	self.ListData:SetWantsKeyEvents(false);
	self.ListData:SetWantsUpdates(false);
	self.ListData:SetVerticalScrollBar();
end
