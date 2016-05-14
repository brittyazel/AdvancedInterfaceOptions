local addonName, addon = ...

function addon:CreateString(parent, text, width, justify)
	local str = parent:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmallLeft')
	str:SetText(text)
	str:SetWordWrap(false) -- hacky bit to truncate string without elipsis
	str:SetNonSpaceWrap(true)
	str:SetHeight(10)
	str:SetMaxLines(2)
	if width then str:SetWidth(width) end
	if justify then str:SetJustifyH(justify) end
	return str
end

-- Scroll frame
local function updatescroll(scroll)
	for line = 1, scroll.slots do
		local lineoffset = line + scroll.value
		if lineoffset <= scroll.itemcount then
			scroll.slot[line].value = scroll.items[lineoffset][1]
			--local text = scroll.items[lineoffset][2]
			--if(scroll.slot[line].value == scroll.selected) then
				--text = "|cffff0000"..text.."|r"
			--end
			--scroll.slot[line].text:SetText(text)
			for i, col in ipairs(scroll.slot[line].cols) do
				col:SetText(scroll.items[lineoffset][i+1])
			end
			--scroll.slot[line].cols[2]:SetText(text)
			scroll.slot[line]:Show()
		else
			--scroll.slot[line].cols[2]:SetText("")
			scroll.slot[line].value = nil
			scroll.slot[line]:Hide()
		end
	end
	
	--scroll.scrollbar:SetValue(scroll.value)
end

local function scrollscripts(scroll, scripts)
	for k,v in pairs(scripts) do
		scroll.scripts[k] = v
	end
	for line = 1, scroll.slots do
		for k,v in pairs(scroll.scripts) do
			scroll.slot[line]:SetScript(k,v)
		end
	end
end

local function selectscrollitem(scroll, value)
	scroll.selected = value
	scroll:Update()
end

local function setscrolllist(scroll, items)
	scroll.items = items
	scroll.itemcount = #items
	scroll.stepValue = min(ceil(scroll.slots / 2), max(floor(scroll.itemcount / scroll.slots), 1))
	scroll.maxValue = max(scroll.itemcount - scroll.slots, 0)
	--scroll.value = scroll.minValue
	scroll.value = scroll.value <= scroll.maxValue and scroll.value or scroll.maxValue
	
	scroll.scrollbar:SetMinMaxValues(0, scroll.maxValue)
	scroll.scrollbar:SetValue(scroll.value)
	scroll.scrollbar:SetValueStep(scroll.stepValue)
	
	scroll:Update()
end

local function normalize(str)
	str = str and gsub(str, '|c........', '') or ''
	return str:gsub('(%d+)', function(d)
		local lenf = strlen(d)
		return lenf < 10 and (strsub('0000000000', lenf + 1) .. d) or d -- or ''
		--return (d + 0) < 2147483648 and string.format('%010d', d) or d -- possible integer overflow
	end):gsub('%W', ''):lower()
end

local function sortItems(scroll, col)
	-- todo: Keep items sorted when :Update() is called
	-- todo: Show a direction icon on the sorted column
	-- Force it in one direction if we're sorting a different column than was previously sorted
	if col ~= scroll.sortCol then
		scroll.sortUp = nil
		scroll.sortCol = col
	end
	if scroll.sortUp then
		table.sort(scroll.items, function(a, b) return normalize(a[col]) > normalize(b[col]) end)
		scroll.sortUp = false
	else
		table.sort(scroll.items, function(a, b) return normalize(a[col]) < normalize(b[col]) end)
		scroll.sortUp = true
	end
	scroll:Update()
end

local function scroll(self, arg1)
	if ( self.maxValue > self.minValue ) then
		if ( self.value > self.minValue and self.value < self.maxValue )
		or ( self.value == self.minValue and arg1 == -1 )
		or ( self.value == self.maxValue and arg1 == 1 ) then
			local newval = self.value - arg1 * self.stepValue
			if ( newval <= self.maxValue and newval >= self.minValue ) then
				self.value = newval
			elseif ( newval > self.maxValue ) then
				self.value = self.maxValue
			elseif ( newval < self.minValue ) then
				self.value = self.minValue
			end
		elseif ( self.value < self.minValue ) then
			self.value = self.minValue
		elseif ( self.value > self.maxValue ) then
			self.value = self.maxValue
		end
		self:Update()
	end
	self.scrollbar:SetValue(self.value)
end

function addon:CreateListFrame(parent, w, h, cols)
	local frame = CreateFrame('Frame', nil, parent, 'InsetFrameTemplate')
	frame:SetSize(w, h)
	frame:SetFrameLevel(1)
	
	frame.scripts = {
		--["OnMouseDown"] = function(self) print(self.text:GetText()) end
	}
	frame.selected = nil
	frame.items = {}
	frame.itemcount = 0
	frame.minValue = 0
	frame.itemheight = 15
	frame.slots = floor((frame:GetHeight()-10)/frame.itemheight)
	frame.slot = {}
	frame.stepValue = min(frame.slots, max(floor(frame.itemcount / frame.slots), 1))
	frame.maxValue = max(frame.itemcount - frame.slots, 0)
	frame.value = frame.minValue

	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", scroll)

	frame.Update = updatescroll
	frame.SetItems = setscrolllist
	frame.SortBy = sortItems
	frame.SetScripts = scrollscripts
	
	-- scrollbar
	local scrollUpBg = frame:CreateTexture(nil, nil, 1)
	scrollUpBg:SetTexture([[Interface\ClassTrainerFrame\UI-ClassTrainer-ScrollBar]])
	scrollUpBg:SetPoint('TOPRIGHT', 0, -2)--TOPLEFT', scrollbar, 'TOPRIGHT', -3, 2)
	scrollUpBg:SetTexCoord(0, 0.46875, 0.0234375, 0.9609375)
	scrollUpBg:SetSize(30, 120)
	
	
	local scrollDownBg = frame:CreateTexture(nil, nil, 1)
	scrollDownBg:SetTexture([[Interface\ClassTrainerFrame\UI-ClassTrainer-ScrollBar]])
	scrollDownBg:SetPoint('BOTTOMRIGHT', 0, 1)
	scrollDownBg:SetTexCoord(0.53125, 1, 0.03125, 1)
	scrollDownBg:SetSize(30, 123)
	
	
	local scrollMidBg = frame:CreateTexture(nil, nil, 0) -- fill in the middle gap, a bit hacky
	scrollMidBg:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]], false, true)
	--scrollMidBg:SetPoint('RIGHT', -1, 0)
	scrollMidBg:SetTexCoord(0, 0.445, 0.75, 1)
	--scrollMidBg:SetSize(28, 80)
	--scrollMidBg:SetWidth(28)
	scrollMidBg:SetPoint('TOPLEFT', scrollUpBg, 'BOTTOMLEFT', 1, 0)
	scrollMidBg:SetPoint('BOTTOMRIGHT', scrollDownBg, 'TOPRIGHT', -1, 0)
	
	
	

	local scrollbar = CreateFrame('Slider', nil, frame, 'UIPanelScrollBarTemplate')
	--scrollbar:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 4, -16)
	--scrollbar:SetPoint('BOTTOMLEFT', frame, 'BOTTOMRIGHT', 4, 16)
	scrollbar:SetPoint('TOP', scrollUpBg, 2, -18)
	scrollbar:SetPoint('BOTTOM', scrollDownBg, 2, 18)
	scrollbar.ScrollUpButton:SetScript('OnClick', function() scroll(frame, 1) end)
	scrollbar.ScrollDownButton:SetScript('OnClick', function() scroll(frame, -1) end)
	scrollbar:SetScript('OnValueChanged', function(self, value)
		frame.value = floor(value)
		frame:Update()
		if frame.value == frame.minValue then self.ScrollUpButton:Disable()
		else self.ScrollUpButton:Enable() end
		if frame.value >= frame.maxValue then self.ScrollDownButton:Disable()
		else self.ScrollDownButton:Enable() end
	end)
	frame.scrollbar = scrollbar
	
	local padding = 4
	-- columns
	frame.cols = {}
	local offset = 0
	for i, colTbl in ipairs(cols) do
		local name, width, justify = colTbl[1], colTbl[2], colTbl[3]
		local col = CreateFrame('Button', nil, frame)
		col:SetNormalFontObject('GameFontHighlightSmallLeft')
		col:SetHighlightFontObject('GameFontNormalSmallLeft')
		col:SetPoint('BOTTOMLEFT', frame, 'TOPLEFT', 8 + offset, 0)
		col:SetSize(width, 18)
		col:SetText(name)
		col:GetFontString():SetAllPoints()
		if justify then
			col:GetFontString():SetJustifyH(justify)
			col.justify = justify
		end
		col.offset = offset
		col.width = width
		offset = offset + width + padding
		frame.cols[i] = col
		
		col:SetScript('OnClick', function(self)
			frame:SortBy(i+1)
		end)
	end
	

	-- rows
	for slot = 1, frame.slots do
		local f = CreateFrame("frame", nil, frame)
		f.cols = {}
		
		local bg = f:CreateTexture()
		bg:SetAllPoints()
		bg:SetColorTexture(1,1,1,0.1)
		bg:Hide()
		f.bg = bg
		
		f:EnableMouse(true)
		f:SetWidth(frame:GetWidth() - 38)
		f:SetHeight(frame.itemheight)
		
		for i, col in ipairs(frame.cols) do
			local str = addon:CreateString(f, 'x')
			str:SetPoint('LEFT', col.offset, 0)
			str:SetWidth(col.width)
			if col.justify then
				str:SetJustifyH(col.justify)
			end
			f.cols[i] = str
		end
		
		--[[
		local str = addon:CreateString(f, "Scroll_Slot_"..slot)
		str:SetAllPoints(f)
		str:SetWordWrap(false)
		str:SetNonSpaceWrap(false)
		--str:SetWidth(frame:GetWidth() - 50)
		--]]
		
		frame.slot[slot] = f
		if(slot > 1) then
			f:SetPoint("TOPLEFT", frame.slot[slot-1], "BOTTOMLEFT")
		else
			f:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
		end
		--f.text = str
	end
	
	
	frame:Update()
	return frame
end

--[[
local function npcprep(npctable, scroll)
	local newtable = {}
	for npcID,v in pairs(npctable) do
		tinsert(newtable, v)
	end
	sort(newtable, function(a,b) return a[2] < b[2] end)
	setscrolllist(scroll, newtable)
end
--]]

local RoleStrings = {
	TANK = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:32:48:0:16|t',
	HEALER = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:48:64:0:16|t',
	DAMAGER = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:16:32:0:16|t',
}

--[[
local waitList = newscroll(nil, UIParent, 310, 240, {{LEVEL_ABBR, 20, 'RIGHT'}, {NAME, 158}, {ITEM_LEVEL_ABBR, 25, 'RIGHT'},{RoleStrings['TANK'], 16, 'CENTER'}, {RoleStrings['HEALER'], 16, 'CENTER'}, {RoleStrings['DAMAGER'], 16, 'CENTER'}})
waitList:SetPoint('CENTER')
--left:SetPoint("TOPRIGHT", model, "TOPLEFT", -5, 0)
local creatures = {}
for i=1, 100 do
	tinsert(creatures, {random(60,90),"Name Placeholder "..i,random(460, 570),RoleStrings['TANK'], RoleStrings['HEALER'], RoleStrings['DAMAGER']})
end
--npcprep(creatures, left)
setscrolllist(waitList, creatures)


scrollscripts(waitList, {
	--["OnMouseDown"] = function(self)
	--	selectscrollitem(waitList, self.value)
	--end,
	["OnEnter"] = function(self)
		self.bg:Show()
	end,
	["OnLeave"] = function(self)
		self.bg:Hide()
	end,
})
--]]

--[[
local waitList = newscroll(nil, UIParent, 310, 240, {{CALENDAR_EVENT_DESCRIPTION, 148}, {ITEM_LEVEL_ABBR, 25, 'RIGHT'}, {RoleStrings['TANK'], 28, 'RIGHT'}, {RoleStrings['HEALER'], 28, 'RIGHT'}, {RoleStrings['DAMAGER'], 28, 'RIGHT'}})
waitList:SetPoint('CENTER')
--left:SetPoint("TOPRIGHT", model, "TOPLEFT", -5, 0)
local creatures = {}
for i=1, 100 do
	tinsert(creatures, {"Flex 1st wing, fresh!"..i, random(460, 570), random(0,2) .. ' ' .. RoleStrings['TANK'], random(0,6) .. ' ' .. RoleStrings['HEALER'], random(0,17) .. ' ' .. RoleStrings['DAMAGER']})
end
--npcprep(creatures, left)
--setscrolllist(waitList, creatures)
waitList:SetItems(creatures)
--]]
--table.sort(creatures, function(a,b) return a[1] < b[1] end)
--waitList:Update()


-- Input boxes
function addon:CreateInput(parent, width, defaultText, maxChars, numeric)
	local editbox = CreateFrame('EditBox', nil, parent)
	
	editbox:SetTextInsets(5, 0, 0, 0)
	
	local borderLeft = editbox:CreateTexture(nil, 'BACKGROUND')
	borderLeft:SetTexture([[Interface\Common\Common-Input-Border]])
	borderLeft:SetSize(8, 20)
	borderLeft:SetPoint('LEFT', 0, 0)
	borderLeft:SetTexCoord(0, 0.0625, 0, 0.625)
	
	local borderRight = editbox:CreateTexture(nil, 'BACKGROUND')
	borderRight:SetTexture([[Interface\Common\Common-Input-Border]])
	borderRight:SetSize(8, 20)
	borderRight:SetPoint('RIGHT', 0, 0)
	borderRight:SetTexCoord(0.9375, 1, 0, 0.625)
	
	local borderMiddle = editbox:CreateTexture(nil, 'BACKGROUND')
	borderMiddle:SetTexture([[Interface\Common\Common-Input-Border]])
	borderMiddle:SetSize(10, 20)
	borderMiddle:SetPoint('LEFT', borderLeft, 'RIGHT')
	borderMiddle:SetPoint('RIGHT', borderRight, 'LEFT')
	borderMiddle:SetTexCoord(0.0625, 0.9375, 0, 0.625)
	
	editbox:SetFontObject('ChatFontNormal')
	
	editbox:SetSize(width or 8, 20)
	editbox:SetAutoFocus(false)
	
	if defaultText then
		local placeholderText = addon:CreateString(editbox, defaultText, width or 8)
		placeholderText:SetFontObject('GameFontDisableLeft')
		placeholderText:SetPoint('LEFT', 5, 0)
		
		editbox:SetScript('OnEditFocusLost', function(self)
			if self:GetText() == '' then
				placeholderText:Show()
			else
				EditBox_ClearHighlight(self)
			end
		end)
		
		editbox:SetScript('OnEditFocusGained', function(self)
			placeholderText:Hide()
			EditBox_HighlightText(self)
		end)
	else
		editbox:SetScript('OnEditFocusLost', EditBox_ClearHighlight)
		editbox:SetScript('OnEditFocusGained', EditBox_HighlightText)
	end

	editbox:SetScript('OnEscapePressed', EditBox_ClearFocus)
	--editbox:SetScript('OnEditFocusLost', EditBox_ClearHighlight)
	--editbox:SetScript('OnEditFocusGained', EditBox_HighlightText)
	editbox:SetScript('OnTabPressed', function(self)
		if self.tabTarget then
			self.tabTarget:SetFocus()
		end
	end)
	if maxChars then
		editbox:SetMaxLetters(maxChars)
	end
	if numeric then
		editbox:SetNumeric(true)
	end
	--editbox:SetText(defaultText or '')
	return editbox
end

-- Dropdown Menus
local DropdownCount = 0

local function initmenu(items)
	
	local info = UIDropDownMenu_CreateInfo()
	info.text = 'Challenge Mode' --GUILD_CHALLENGE_TYPE2
	info.func = function() return end
	UIDropDownMenu_AddButton(info)
end

function addon:CreateDropdown(parent, width, items, defaultValue)
	local dropdown = CreateFrame('frame', addonName .. 'DropDownMenu' .. DropdownCount, parent, 'UIDropDownMenuTemplate')
	DropdownCount = DropdownCount + 1
	--groupTypeDropdown:SetPoint('LEFT', ilevelInput, 'RIGHT', -5, -3)
	--groupTypeDropdown:SetPoint('TOPRIGHT', titleInput, 'BOTTOMRIGHT', 16, -8)
	--dropdown:SetPoint('BOTTOMRIGHT', parent, 10, 0)
	
	UIDropDownMenu_Initialize(dropdown, function()
		for i, tbl in ipairs(items) do
			local info = UIDropDownMenu_CreateInfo()
			--info.value = v[1]
			--info.text = v[2]

			for k, v in pairs(tbl) do
				info[k] = v
			end
			
			
			info.func = function(self)
   			--UIDropDownMenu_SetSelectedID(dropdown, self:GetID(), true)
   			UIDropDownMenu_SetSelectedValue(dropdown, self.value)
			end
			
			--if info.isTitle then
				--info.text = '-' .. info.text .. '-'
			--end
			
			UIDropDownMenu_AddButton(info)
		end
	end)
	
	--UIDropDownMenu_SetSelectedID(dropdown, defaultID or 1)
	UIDropDownMenu_SetSelectedValue(dropdown, defaultValue)
	UIDropDownMenu_SetWidth(dropdown, width or 160)
	
	_G[dropdown:GetName() .. 'Button']:HookScript('OnClick', function(self)
		DropDownList1:ClearAllPoints()
		DropDownList1:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, 0)
		--ToggleDropDownMenu(nil, nil, dropdown, dropdown, 0, 0)
	end)
	
	return dropdown
end

do return end
-- Simplify the creation of ui elements by defining common widgets here
local addonName, addon = ...

function addon:CreateString(parent, template)
	local str = parent:CreateFontString(nil, nil, template or 'GameFontHighlightSmallLeft')
	str:SetWordWrap(false)
	return str
end

-- ScrollFrame - A scrollable frame with sortable columns
function addon:CreateListFrame(name, parent, width, height, names, widths, rowHeight) -- max height is 243 because of the scrollbar background
	local f = CreateFrame('Frame', nil, parent, 'InsetFrameTemplate')
	f:SetSize(width or 1, height or 1)
	f:SetFrameLevel(1)
	
	local scrollFrame = CreateFrame('ScrollFrame', name, f, 'ListScrollFrameTemplate')
	scrollFrame:SetPoint('TOPLEFT', 4, -4)
	scrollFrame:SetPoint('BOTTOMRIGHT', -28, 4)
	f.scrollFrame = scrollFrame
	
	local scrollChild = scrollFrame:GetScrollChild()
	scrollChild:SetAllPoints()
	--scrollChild:SetSize(310, 100)
	f.child = scrollChild
	
	f.scrollBar = _G[name .. 'ScrollBar']
	
	f.cols = {}
	local offset = 5
	for i, name in ipairs(names) do
		local col = CreateFrame('Button', nil, f)
		col:SetNormalFontObject('GameFontHighlightSmallLeft')
		col:SetHighlightFontObject('GameFontNormalSmallLeft')
		--col:SetPoint('BOTTOMLEFT', parent, 'TOPLEFT', offset, 0)
		col:SetPoint('BOTTOMLEFT', scrollFrame, 'TOPLEFT', offset, 4)
		col:SetSize(widths[i], 15)
		col:SetText(name)
		col.offset = offset
		col.width = widths[i]
		offset = offset + widths[i]
		f.cols[i] = col
	end
	
	local slots = ceil(scrollChild:GetHeight() / rowHeight)
	
	f.rows = {}
	for i = 1, slots do
		local row = CreateFrame('Frame', nil, scrollChild)
		row:SetPoint('TOPLEFT', scrollChild, 'TOPLEFT', 0, (i-1) * -rowHeight)
		row:SetPoint('BOTTOMRIGHT', scrollChild, 'TOPRIGHT', 0, i * -rowHeight)
		
		local bg = row:CreateTexture(nil, 'BACKGROUND')
		bg:SetColorTexture(1,0,0,0.1)
		bg:SetAllPoints()
		bg:Hide()
		row.bg = bg
		
		row:EnableMouse(true)
		row:SetScript('OnEnter', function(self) self.bg:Show() end)
		row:SetScript('OnLeave', function(self) self.bg:Hide() end)
		
		f.rows[i] = row
		row.cols = {}
		for c, col in ipairs(f.cols) do
			local str = addon:CreateString(row)
			str:SetPoint('LEFT', col.offset, 0)
			str:SetWidth(col.width)
			row.cols[c] = str
		end
	end
	
	--scrollChild:SetSize(width, rowHeight * slots)
	
	--FauxScrollFrame_Update(scrollFrame, 0, slots, rowHeight)
	
	f.slots = slots
	f.rowHeight = rowHeight
	
	return f
end

local RoleStrings = {
	TANK = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:32:48:0:16|t',
	HEALER = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:48:64:0:16|t',
	DAMAGER = '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:16:32:0:16|t',
}

local f = addon:CreateListFrame('MyScrollyFrame', UIParent, 310, 240, {LEVEL_ABBR, NAME, ITEM_LEVEL_ABBR, '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:32:48:0:16|t', '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:48:64:0:16|t', '|TInterface/LFGFrame/LFGRole:16:16:0:0:64:16:16:32:0:16|t'}, {20, 180, 25, 16, 16, 16}, 18)
f:SetPoint('CENTER')

for i, row in ipairs(f.rows) do -- hackishly add some buttons
	local rejectButton = CreateFrame('button', nil, row, 'UIPanelButtonTemplate')
	rejectButton:SetNormalFontObject('GameFontHighlightSmall')
	rejectButton:SetSize(20, 18)
	rejectButton:SetPoint('RIGHT', row.cols[2])
	rejectButton:SetText('x')
	
	local inviteButton = CreateFrame('button', nil, row, 'UIPanelButtonTemplate')
	inviteButton:SetNormalFontObject('GameFontHighlightSmall')
	inviteButton:SetSize(50, 18)
	inviteButton:SetPoint('RIGHT', rejectButton, 'LEFT')
	inviteButton:SetText(INVITE)
	
	row.cols[3]:SetJustifyH('RIGHT')
end

local datas = {
	{'90', 'Name-Placeholder1', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder2', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder3', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder4', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder5', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder6', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder7', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder8', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder9', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder10', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder11', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder12', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder13', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder14', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder15', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder16', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder17', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder18', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder19', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder20', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder21', '500', RoleStrings.TANK, '', ''},
	{'90', 'Name-Placeholder22', '400', '', '', RoleStrings.DAMAGER},
	{'90', 'Name-Placeholder23', '550', '', RoleStrings.HEALER, ''},
	{'90', 'Name-Placeholder24', '580', RoleStrings.TANK, '', RoleStrings.DAMAGER},
}

--[[
function addon:PopulateList(listFrame, datas)
	for i, row in ipairs(f.rows) do
		if datas[i] then
			for c, col in ipairs(row.cols) do
				col:SetText(datas[i][c])
			end
			row:Show()
		else
			row:Hide()
		end
	end
end
--]]

function addon:UpdateList(listFrame, datas)
	--listFrame.child:SetHeight(#datas * listFrame.rowHeight)
	FauxScrollFrame_Update(listFrame.scrollFrame, #datas, listFrame.slots, listFrame.rowHeight)
	for i, row in ipairs(f.rows) do
		offset = i + FauxScrollFrame_GetOffset(listFrame.scrollFrame)
		if datas[offset] then
			for c, col in ipairs(row.cols) do
				col:SetText(datas[offset][c])
			end
			row:Show()
		else
			row:Hide()
		end
	end
end

addon:UpdateList(f, datas)
f.scrollFrame:SetScript('OnVerticalScroll', function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, 18, function() addon:UpdateList(f, datas) end)
end)


-- Input boxes with labels that can be tabbed between

-- Simple dropdown menus
