if importPath==nil then importPath=string.gsub(getfenv(1)._.Name,"%.TableView","").."." end
if resourcePath==nil then resourcePath=string.gsub(importPath,"%.","/").."Resources/" end

-- this will create a table view of the provided table
-- a separate table with column info can be provided with column label, name, minSize, size (fixed width), show

-- to do
-- drag header to reorder columns
-- custom colors

if FontMetric==nil then
	import (importPath.."FontSupport")
	fontMetric=FontMetric
end
-- no .MouseWheel on Control
-- no .SizeChanged on Label, TextBox or Button
-- TreeView, ListBox work, apparently any control that natively has child controls
fontMetric:SetFont(Turbine.UI.Lotro.Font.Verdana20)
ColumnMenu=Turbine.UI.ContextMenu()
TableView=class(Turbine.UI.TreeView)
function TableView:Constructor(columns,data)
	Turbine.UI.TreeView.Constructor(self)
	self.ViewPort=Turbine.UI.Control()
	self.ViewPort:SetParent(self)
	self.Header=Turbine.UI.Control()
	self.Header:SetParent(self.ViewPort)
	self.DataList=Turbine.UI.ListBox()
	self.DataList:SetParent(self.ViewPort)
	self.VScroll=Turbine.UI.Lotro.ScrollBar()
	self.VScroll:SetParent(self)
	self.VScroll:SetOrientation(Turbine.UI.Orientation.Vertical)
	self.DataList:SetVerticalScrollBar(self.VScroll)
	self.HScroll=Turbine.UI.Lotro.ScrollBar()
	self.HScroll:SetParent(self)
	self.HScroll:SetLeft(0)
	self.HScroll:SetValue(0)
	self.HScroll:SetOrientation(Turbine.UI.Orientation.Horizontal)
	self.HScroll:SetSize(0,10)
	self.VScroll:SetSize(10,0)
	self.HScroll.ValueChanged=function()
		self.Header:SetLeft(0-self.HScroll:GetValue())
		self.DataList:SetLeft(0-self.HScroll:GetValue())
	end
	self.Font=Turbine.UI.Lotro.Font.Verdana20 -- default
	self.FontSize=20
	self:SetSize(200,200)
	self.HScroll:SetVisible(false)
	self.VScroll:SetVisible(false)
	self.ViewPort:SetSize(190,190)
	self.ViewPort:SetBackColor(Turbine.UI.Color(.2,.2,.2))
	self.ViewPort:SetMouseVisible(false)
	self.Header:SetSize(0,20)
	self.Header.Cols={}
	self.Header:SetSize(0,20)
	self.Header:SetMouseVisible(false)
	self.MovingHeader=Turbine.UI.Label()
	self.MovingHeader:SetParent(self.Header)
	self.MovingHeader:SetMultiline(false)
	self.MovingHeader:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
	self.MovingHeader:SetBackColor(Turbine.UI.Color(.2,.2,.35))
	self.MovingHeader:SetForeColor(Turbine.UI.Color.White)
	self.MovingHeader:SetVisible(false)
	self.MovingHeader:SetZOrder(1)
	self.DataList:SetPosition(0,20)
	self.DataList:SetMouseVisible(false)
	self.Columns={}
	self.Layout=function()
		local newWidth,newHeight=self:GetSize()
		self.VScroll:SetPosition(newWidth-10,self.Header:GetHeight())
		self.VScroll:SetHeight(newHeight-self.Header:GetHeight()-10)
		self.HScroll:SetTop(newHeight-10)
		self.HScroll:SetWidth(newWidth-20)
		self.ViewPort:SetSize(newWidth-10,newHeight-10)
		self.DataList:SetHeight(self.VScroll:GetHeight())
		if self.Header:GetWidth()>self.ViewPort:GetWidth() then
			self.HScroll:SetMinimum(0)
			self.HScroll:SetMaximum(self.Header:GetWidth()-self.ViewPort:GetWidth())
			if self.HScroll:IsVisible() then
				self.HScroll:SetValue(0-self.Header:GetLeft())
			else
				self.HScroll:SetValue(0)
				self.HScroll:SetVisible(true)
			end
		else
			self.Header:SetLeft(0)
			self.DataList:SetLeft(0)
			self.HScroll:SetVisible(false)
			self.HScroll:SetValue(0)
		end
	end
	self.SizeChanged=function()
		-- move controls based on window size
		self.Layout()
		-- now fire Refresh to resize controls based on font
		self.Refresh()
	end
	self.SetHeaderBackColor=function()
	end
	self.SetBackColor=function()
	end
	self.SetHeaderColor=function()
	end
	self.SetForeColor=function()
	end
	self.SetTrimColor=function()
	end
	self.SetFont=function(sender,font)
		local fontInfo=Turbine.UI.Lotro.FontInfo[font]
		if fontInfo~=nil then
			self.Font=font
			self.FontSize=fontInfo.size
		else
			-- invalid font
		end
		self.Refresh()
	end
	self.Refresh=function()
		-- refreshes grid, necessary after any data change, size change, font change or column visibility change
		fontMetric:SetFont(self.Font)
		-- resize controls for new font size
		self.Header:SetHeight(self.FontSize)
		self.VScroll:SetHeight(self:GetHeight()-self.FontSize-10)
		self.DataList:SetTop(self.FontSize)
		self.DataList:SetHeight(self.VScroll:GetHeight())
		local left=0
		for row=1,self.DataList:GetItemCount() do
			self.DataList:GetItem(row).MinHeight=self.FontSize
		end
		local rowWidth=0
		for k, v in ipairs(self.Columns) do
			-- header
			local h=self.Header.Cols[k]
			local newWidth=self.Columns[k].width
			h.header:SetHeight(self.FontSize)
			h.header:SetFont(self.Font)
			h.header:SetText(h.header:GetText())
			h.sep:SetHeight(self.FontSize)
			h.header:SetVisible(self.Columns[k].show)
			h.sep:SetVisible(self.Columns[k].show)
			if newWidth==nil then
				if v.label~=nil and v.label~="" then
					newWidth=fontMetric:GetTextWidth(v.label,self.FontSize)
					if newWidth<v.minWidth then newWidth=v.minWidth end
				else
					newWidth=0 --??? what's a good default for an empty column?
				end
				h.header:SetWidth(newWidth)
			end
			h.header:SetLeft(left)
			h.sep:SetLeft(left+newWidth)
			-- data
			for row=1,self.DataList:GetItemCount() do
				local tmpRow=self.DataList:GetItem(row)
				local cell=tmpRow.Cell[k]
				local tmpText=self.Data[row][self.Columns[k].name] -- get the data from the source since columns may have changed order
				local tmpSize=tmpRow.MinHeight -- what's a safe size for an empty cell?
				if tmpText~=nil and tmpText~="" then
					tmpSize=fontMetric:GetTextHeight(tmpText,newWidth)
					if tmpSize>tmpRow.MinHeight then tmpRow.MinHeight=tmpSize end
				end
				cell:SetHeight(tmpRow.MinHeight)
				cell:SetVisible(self.Columns[k].show)
				cell:SetFont(self.Font)
				cell:SetText(string.gsub(tmpText,"<","|")) -- temporarily escape the "<" character to prevent the label from processing tags
				local tmpPos=string.find(tmpText,"<")
				while tmpPos~=nil and tmpPos<=string.len(tmpText) do
					cell:SetSelection(tmpPos,1)
					cell:SetSelectedText("<")
					tmpPos=string.find(tmpText,"<",tmpPos+1)
				end
				cell:SetSelection(0,0)

				cell:SetLeft(left)
				cell:SetWidth(newWidth)
			end
			if self.Columns[k].show then
				rowWidth=rowWidth+newWidth+3
				left=left+newWidth+3
			end
		end
		self.Header:SetWidth(rowWidth)
		for row=1,self.DataList:GetItemCount() do
			local tmpRow=self.DataList:GetItem(row)
			tmpRow:SetWidth(rowWidth)
			local height=tmpRow.MinHeight
			if height>self.FontSize then
				tmpRow:SetHeight(height)
				for k,v in ipairs(tmpRow.Cell) do
					v:SetHeight(height)
				end
			end
		end
		self.DataList:SetWidth(rowWidth)
		if rowWidth>self.ViewPort:GetWidth() then
			self.HScroll:SetMinimum(0)
			self.HScroll:SetMaximum(rowWidth-self.ViewPort:GetWidth())
			if self.HScroll:IsVisible() then
				self.HScroll:SetValue(0-self.Header:GetLeft())
			else
				self.HScroll:SetValue(0)
				self.HScroll:SetVisible(true)
			end
		else
			self.Header:SetLeft(0)
			self.DataList:SetLeft(0)
			self.HScroll:SetVisible(false)
			self.HScroll:SetValue(0)
		end
	end
	self.MoveColumn=function(sender,colIndex,newIndex)
		-- need to update self.Columns, self.Header.Cols, ColumnMenu, then call Refresh
		local tmpList=ColumnMenu:GetItems()
		tmpCol=tmpList:Get(colIndex)
		tmpList:RemoveAt(colIndex)
		if colIndex<newIndex then
			tmpList:Insert(newIndex-1,tmpCol)
			table.insert(self.Columns,newIndex-1,table.remove(self.Columns,colIndex))
			table.insert(self.Header.Cols,newIndex-1,table.remove(self.Header.Cols,colIndex))
		else
			tmpList:Insert(newIndex,tmpCol)
			table.insert(self.Columns,newIndex,table.remove(self.Columns,colIndex))
			table.insert(self.Header.Cols,newIndex,table.remove(self.Header.Cols,colIndex))
		end

		-- now reindex the menu and header cols
		for k=1,tmpList:GetCount() do
			tmpList:Get(k).Col=k
		end
		for k,v in ipairs(self.Header.Cols) do
			v.header.Col=k
			v.sep.Col=k
		end
		self.Refresh()
	end
	self.ShowTable=function(sender,columns,data)
		fontMetric:SetFont(self.Font)
		if data==nil then
			if columns~=nil then
				--no columns actually provided
				data=columns
				columns=nil
			end
		end
		if columns==nil and data~=nil then
			columns={}
			-- create the columns table from the first row of data
			for k,v in pairs(data[1]) do
				table.insert(columns,{label=tostring(k),name=k,show=true})
			end
		end
		-- clear any existing data
		for k,v in ipairs(self.Header.Cols) do
			local tmpCol=self.Header.Cols[k]
			v.header:SetVisible(false)
			v.sep:SetVisible(false)
			v.sep.MouseDown=nil
			v.sep.MouseMove=nil
			v.sep.MouseUp=nil
			v.header=nil
			v.sep=nil
			self.Header.Cols[k]=nil
		end
		-- clear the context menu
		local menuItems=ColumnMenu:GetItems()
		-- remove click events
		for k=1,menuItems:GetCount() do
			menuItems:Get(k).Click=nil
		end
		menuItems:Clear()
		self.DataList:ClearItems()
		self.Header.Cols={}
		self.Header:SetSize(0,self.FontSize)

		-- now show new columns
		self.Columns=columns
		self.Data=data
		for k,v in ipairs(self.Columns) do
			local left=self.Header:GetWidth()
			if v.label==nil then v.label=tostring(k) end
			if v.name==nil then v.name=k end -- use numerics
			if v.minWidth==nil then v.minWidth=0 end

			local menuItem=Turbine.UI.MenuItem(v.label)
			if v.show then menuItem:SetChecked(true) end
			menuItem.Col=k
			menuItem.Click=function(sender,args)
				local show=not sender:IsChecked()
				self.Columns[sender.Col].show=show
				sender:SetChecked(show)
				self.Refresh()
			end
			menuItems:Add(menuItem)

			-- create header for each column
			local tmpHeader=Turbine.UI.Label()
			local tmpSep=Turbine.UI.Control()
			tmpHeader:SetParent(self.Header)
			tmpSep:SetParent(self.Header)
			tmpSep:SetSize(3,self.FontSize)
			local tmpSize=v.width
			if tmpSize==nil then
				tmpSize=fontMetric:GetTextWidth(v.label,self.FontSize)
				if tmpSize<v.minWidth then tmpSize=v.minWidth end
			end
			tmpHeader:SetSize(tmpSize,self.FontSize)
			tmpHeader:SetFont(self.Font)
			tmpHeader:SetMultiline(false)
			tmpHeader:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter);
			tmpHeader:SetText(v.label)
			tmpHeader:SetLeft(left)
			tmpSep:SetLeft(tmpHeader:GetWidth()+left)
			tmpHeader:SetVisible(v.show)
			tmpSep:SetVisible(v.show)
			tmpSep:SetBackColor(Turbine.UI.Color.White)
			tmpHeader.Col=k
			tmpSep.Col=k
			tmpHeader:SetBackColor(Turbine.UI.Color(.1,.1,.2))
			tmpHeader:SetForeColor(Turbine.UI.Color.White)
			if v.show then
				self.Header:SetWidth(left+tmpHeader:GetWidth()+3)
			end
			-- column move stuff
			tmpHeader.MouseDown=function(sender,args)
				if args.Button==1 then
					sender.moveX=args.X
					sender.moving=true
					self.MovingHeader:SetPosition(sender:GetLeft(),sender:GetTop())
					self.MovingHeader:SetSize(sender:GetWidth(),sender:GetHeight())
					self.MovingHeader:SetFont(self.Font)
					self.MovingHeader:SetText(sender:GetText())
					self.MovingHeader:SetVisible(true)
				end
			end
			tmpHeader.MouseMove=function(sender,args)
				if sender.moving then
					self.MovingHeader:SetLeft(self.MovingHeader:GetLeft()-sender.moveX+args.X)
					sender.moveX=args.X
				end
			end
			tmpHeader.MouseUp=function(sender,args)
				sender.moving=false
				self.MovingHeader:SetVisible(false)
				local centerX=self.MovingHeader:GetLeft()+self.MovingHeader:GetWidth()/2
				-- now figure our which column the center of the movingheader is over
				local newIndex
				for k,v in ipairs(self.Header.Cols) do
					if v.header:IsVisible() and v.header:GetLeft()<centerX and (v.header:GetLeft()+v.header:GetWidth())>centerX then
						if centerX<v.header:GetLeft()+v.header:GetWidth()/2 then
							newIndex=k
						else
							newIndex=k+1
						end
						break
					end
				end
				if newIndex~=nil and newIndex~=sender.Col and newIndex~=sender.Col+1 then
					self:MoveColumn(sender.Col,newIndex)			
				end
			end
			tmpHeader.MouseClick=function(sender,args)
				if args.Button==2 then
					local x,y=Turbine.UI.Display:GetMousePosition()
					ColumnMenu:ShowMenuAt(x+2,y-5);
				end
			end

			tmpSep.moving=false
			tmpSep.MouseDown=function(sender,args)
				sender.moveX=args.X
				sender.moving=true
			end
			tmpSep.MouseMove=function(sender,args)
				if tmpSep.moving then
					local delta=args.X-sender.moveX
					local newLeft=sender:GetLeft()+delta
					local newWidth=newLeft-self.Header.Cols[sender.Col].header:GetLeft()
					local minWidth=self.Columns[sender.Col].minWidth
					if minWidth~=nil and newWidth<minWidth then
						newWidth=minWidth
						newLeft=self.Header.Cols[sender.Col].header:GetLeft()+newWidth
						delta=newLeft-sender:GetLeft()
					end
					self.Header.Cols[sender.Col].header:SetWidth(newWidth)
					sender:SetLeft(newLeft)
					-- now, reposition all the columns AFTER this separator
					for k=sender.Col+1,#self.Header.Cols do
						self.Header.Cols[k].header:SetLeft(self.Header.Cols[k].header:GetLeft()+delta)
						self.Header.Cols[k].sep:SetLeft(self.Header.Cols[k].sep:GetLeft()+delta)
					end
					-- lastly, resize Header
					self.Header:SetWidth(self.Header:GetWidth()+delta)
				end
			end
			tmpSep.MouseUp=function(sender,args)
				tmpSep.moving=false
				local tmpCol=sender.Col
				local newWidth=self.Header.Cols[tmpCol].header:GetWidth()
				self.Columns[tmpCol].width=newWidth -- updates the underlying Settings.LogColumns
				self.Refresh()
			end
			table.insert(self.Header.Cols,{header=tmpHeader,sep=tmpSep})
		end
		self.DataList:SetWidth(self.Header:GetWidth())
		-- now fill data
		for k,v in ipairs(self.Data) do
			local tmpHeight=self.FontSize
			local tmpRow=Turbine.UI.Control()
			tmpRow:SetParent(self.DataList)
			tmpRow:SetWidth(self.Header:GetWidth())
			tmpRow:SetMouseVisible(false)
			tmpRow.Cell={}
			left=0
			for id,col in ipairs(self.Columns) do
				local tmpWidth=self.Header.Cols[id].header:GetWidth()
				tmpCell=Turbine.UI.Label()
				tmpCell:SetParent(tmpRow)
				tmpCell:SetLeft(left)
				tmpCell:SetBackColor(Turbine.UI.Color.Black)
				local tmpSize=fontMetric:GetTextHeight(v[col.name],tmpWidth)
				if tmpSize>tmpHeight then tmpHeight=tmpSize end
				tmpCell:SetSize(tmpWidth+2,tmpHeight)
				tmpCell:SetMouseVisible(false)
				tmpCell:SetFont(self.Font)
				local tmpText=v[col.name]
				tmpCell:SetText(string.gsub(tmpText,"<","|")) -- temporarily escape the "<" character to prevent the label from processing tags
				local tmpPos=string.find(tmpText,"<")
				while tmpPos~=nil and tmpPos<=string.len(tmpText) do
					tmpCell:SetSelection(tmpPos,1)
					tmpCell:SetSelectedText("<")
					tmpPos=string.find(tmpText,"<",tmpPos+1)
				end
				tmpCell:SetSelection(0,0)

				if col.show then
					left=left+tmpCell:GetWidth()+1
				else
					tmpCell:SetVisible(false)
				end
				table.insert(tmpRow.Cell,tmpCell)
			end
			if tmpHeight>self.FontSize then
				for id,cell in ipairs(tmpRow.Cell) do
					cell:SetHeight(tmpHeight)
				end
			end
			tmpRow:SetHeight(tmpHeight)
			self.DataList:AddItem(tmpRow)
		end
		self.Layout(self)
	end
end
