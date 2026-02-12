local Types = require(script.Parent.Parent.Types)

-- Tables need an overhaul.

--[[
	Iris.Table(
		{
			NumColumns,
			Header,
			RowBackground,
			OuterBorders,
			InnerBorders
		}
	)

	Config = {
		CellPadding: Vector2,
		CellSize: UDim2,
	}

	Iris.NextColumn()
	Iris.NextRow()
	Iris.SetColumnIndex(index: number)
	Iris.SetRowIndex(index: number)

	Iris.NextHeaderColumn()
	Iris.SetHeaderColumnIndex(index: number)

	Iris.SetColumnWidth(index: number, width: number | UDim)
]]

return function(Iris: Types.Internal, widgets: Types.WidgetUtility)
    local Tables: { [Types.ID]: Types.Table } = {}
    local AnyActiveTable: boolean = false
    local ActiveTable: Types.Table? = nil
    local ActiveColumn: number = 0

    table.insert(Iris._postCycleCallbacks, function()
        for _, thisWidget: Types.Table in Tables do
            for rowIndex: number, cycleTick: number in thisWidget.RowCycles do
                if cycleTick < Iris._cycleTick - 1 then
                    local Row: Frame = thisWidget.RowInstances[rowIndex]
                    local RowBorder: Frame = thisWidget.RowBorders[rowIndex - 1]
                    if Row ~= nil then
                        Row:Destroy()
                    end
                    if RowBorder ~= nil then
                        RowBorder:Destroy()
                    end
                    thisWidget.RowInstances[rowIndex] = nil
                    thisWidget.RowBorders[rowIndex - 1] = nil
                    thisWidget.CellInstances[rowIndex] = nil
                    thisWidget.RowCycles[rowIndex] = nil
                end
            end

            thisWidget.RowIndex = 1
            thisWidget.ColumnIndex = 1

            -- update the border container size to be the same, albeit *every* frame!
            local Table = thisWidget.Instance :: Frame
            local BorderContainer: Frame = Table.BorderContainer
            BorderContainer.Size = UDim2.new(1, 0, 0, thisWidget.RowContainer.AbsoluteSize.Y)
        end
    end)

    local function UpdateActiveColumn()
        if AnyActiveTable == false or ActiveTable == nil then
            return
        end

        local TableWidth: number = ActiveTable.RowContainer.AbsoluteSize.Y

        -- handle logic.
    end

    local function ColumnMouseDown(thisWidget: Types.Table, index: number)
        AnyActiveTable = true
        ActiveTable = thisWidget
        ActiveColumn = index
    end

    widgets.registerEvent("InputChanged", function()
        if not Iris._started then
            return
        end
        UpdateActiveColumn()
    end)

    widgets.registerEvent("InputEnded", function(inputObject: InputObject)
        if not Iris._started then
            return
        end
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 and AnyActiveTable then
            AnyActiveTable = false
            ActiveTable = nil
            ActiveColumn = 0
        end
    end)

    local function GenerateCell(thisWidget: Types.Table, index: number, width: UDim)
        local Cell: Frame = Instance.new("Frame")
        Cell.Name = `Cell_{index}`
        Cell.AutomaticSize = Enum.AutomaticSize.Y
        Cell.Size = UDim2.new(width, UDim.new())
        Cell.BackgroundTransparency = 1
        Cell.ZIndex = index
        Cell.LayoutOrder = index
        Cell.ClipsDescendants = true

        widgets.UIPadding(Cell, Iris._config.FramePadding)
        widgets.UIListLayout(Cell, Enum.FillDirection.Vertical, UDim.new())
        -- widgets.UISizeConstraint(Cell, Vector2.new(10, 0))

        return Cell
    end

    local function GenerateColumnBorder(thisWidget: Types.Table, index: number, style: "Light" | "Strong")
        local Border: ImageButton = Instance.new("ImageButton")
        Border.Name = `Border_{index}`
        Border.AnchorPoint = Vector2.new(0.5, 0)
        Border.Size = UDim2.new(0, 5, 1, 0)
        Border.BackgroundTransparency = 1
        Border.AutoButtonColor = false
        Border.Image = ""
        Border.ImageTransparency = 1
        Border.ZIndex = index
        Border.LayoutOrder = index

        local Line = Instance.new("Frame")
        Line.Name = "Line"
        Line.AnchorPoint = Vector2.new(0.5, 0)
        Line.Size = UDim2.new(0, 1, 1, 0)
        Line.Position = UDim2.fromScale(0.5, 0)
        Line.BackgroundColor3 = Iris._config[`TableBorder{style}Color`]
        Line.BackgroundTransparency = Iris._config[`TableBorder{style}Transparency`]
        Line.BorderSizePixel = 0

        Line.Parent = Border

        widgets.applyInteractionHighlights("Background", Border, Line, {
            Color = Iris._config[`TableBorder{style}Color`],
            Transparency = Iris._config[`TableBorder{style}Transparency`],
            HoveredColor = Iris._config.ResizeGripHoveredColor,
            HoveredTransparency = Iris._config.ResizeGripHoveredTransparency,
            ActiveColor = Iris._config.ResizeGripActiveColor,
            ActiveTransparency = Iris._config.ResizeGripActiveTransparency,
        })

        widgets.applyButtonDown(Border, function()
            ColumnMouseDown(thisWidget, index)
        end)

        return Border
    end

    -- creates a new row and all columns, and adds all to the table's row and cell instance tables, but does not parent
    local function GenerateRow(thisWidget: Types.Table, index: number)
        local Row: Frame = Instance.new("Frame")
        Row.Name = `Row_{index}`
        Row.AutomaticSize = Enum.AutomaticSize.Y
        Row.Size = UDim2.fromScale(1, 0)
        if index == 0 then
            Row.BackgroundColor3 = Iris._config.TableHeaderColor
            Row.BackgroundTransparency = Iris._config.TableHeaderTransparency
        elseif thisWidget.arguments.RowBackground == true then
            if (index % 2) == 0 then
                Row.BackgroundColor3 = Iris._config.TableRowBgAltColor
                Row.BackgroundTransparency = Iris._config.TableRowBgAltTransparency
            else
                Row.BackgroundColor3 = Iris._config.TableRowBgColor
                Row.BackgroundTransparency = Iris._config.TableRowBgTransparency
            end
        else
            Row.BackgroundTransparency = 1
        end
        Row.BorderSizePixel = 0
        Row.ZIndex = 2 * index - 1
        Row.LayoutOrder = 2 * index - 1
        Row.ClipsDescendants = true

        widgets.UIListLayout(Row, Enum.FillDirection.Horizontal, UDim.new())

        thisWidget.CellInstances[index] = table.create(thisWidget.arguments.NumColumns)
        for columnIndex = 1, thisWidget.arguments.NumColumns do
            local Cell = GenerateCell(thisWidget, columnIndex, thisWidget.state.widths.value[columnIndex])
            Cell.Parent = Row
            thisWidget.CellInstances[index][columnIndex] = Cell
        end

        thisWidget.RowInstances[index] = Row

        return Row
    end

    local function GenerateRowBorder(thisWidget: Types.Table, index: number, style: "Light" | "Strong")
        local Border = Instance.new("Frame")
        Border.Name = `Border_{index}`
        Border.Size = UDim2.new(1, 0, 0, 0)
        Border.BackgroundTransparency = 1
        Border.ZIndex = 2 * index
        Border.LayoutOrder = 2 * index

        local Line = Instance.new("Frame")
        Line.Name = "Line"
        Line.AnchorPoint = Vector2.new(0, 0.5)
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.BackgroundColor3 = Iris._config[`TableBorder{style}Color`]
        Line.BackgroundTransparency = Iris._config[`TableBorder{style}Transparency`]
        Line.BorderSizePixel = 0

        Line.Parent = Border

        return Border
    end

    -- Editable Table Widget
    do
        type TableChild = {
            key: string,
            depth: number,
            parent: any?,
            path: string,
            rawPath: string,
            value: any,
        }

        local function convertToValue(value: string)
            if value == "true" then
                return true
            elseif value == "false" then
                return false
            elseif tonumber(value) then
                return tonumber(value)
            elseif value:gsub("%s", "") == "" then
                return nil
            else
                return value
            end
        end

        local function convertFromValue(value: any)
            if value == nil then
                return ""
            else
                return tostring(value)
            end
        end

        local function createTableEntry(thisWidget: Types.Widget, name: string)
            local entry = Instance.new("TextButton")
            entry.Text = ""
            entry.Name = name
            entry.Size = UDim2.new(1, 0, 0, 0)
            entry.AutomaticSize = Enum.AutomaticSize.Y
            entry.BackgroundTransparency = 1
            entry.BorderSizePixel = 0
            entry.BackgroundColor3 = Iris._config.FrameBgColor
            entry.BackgroundTransparency = Iris._config.FrameBgTransparency
            entry.ZIndex = thisWidget.ZIndex + 1
            entry:SetAttribute("Table", true)

            local arrow = Instance.new("ImageLabel")
            arrow.Name = "Arrow"
            arrow.Size = UDim2.fromOffset(Iris._config.TextSize, math.ceil(Iris._config.TextSize * 0.8))
            arrow.AutomaticSize = Enum.AutomaticSize.Y
            arrow.BackgroundTransparency = 1
            arrow.BorderSizePixel = 0
            arrow.Position = UDim2.fromScale(0, 0.5)
            arrow.AnchorPoint = Vector2.new(0, 0.5)
            arrow.ImageColor3 = Iris._config.TextColor
            arrow.ImageTransparency = Iris._config.TextTransparency
            arrow.ScaleType = Enum.ScaleType.Fit
            arrow.ZIndex = thisWidget.ZIndex
            arrow.LayoutOrder = 0
            arrow.Parent = entry

            local key = Instance.new("TextLabel")
            key.Name = "Key"
            key.Size = UDim2.new(1, -Iris._config.TextSize, 0, 0)
            key.Position = UDim2.new(0, Iris._config.TextSize, 0, 0)
            key.AutomaticSize = Enum.AutomaticSize.Y
            key.BackgroundTransparency = 1
            key.BorderSizePixel = 0
            key.ZIndex = thisWidget.ZIndex + 2
            key.LayoutOrder = 1
            key.ClipsDescendants = true
            key.Parent = entry

            local padding = Instance.new("UIPadding")
            padding.Parent = entry

            widgets.UISizeConstraint(arrow, Vector2.new(1, 0))
            widgets.UISizeConstraint(key, Vector2.new(1, 0))

            widgets.UIStroke(entry, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)

            widgets.applyTextStyle(key)

            widgets.applyFrameStyle(key)
            widgets.applyFrameStyle(arrow)

            entry.Parent = thisWidget.Instance

            return entry, key, arrow
        end

        local function createInputEntry(thisWidget: Types.Widget, name: string)
            local entry = Instance.new("Frame")
            entry.Name = name
            entry.Size = UDim2.new(1, 0, 0, 0)
            entry.AutomaticSize = Enum.AutomaticSize.Y
            entry.BackgroundColor3 = Iris._config.FrameBgColor
            entry.BackgroundTransparency = Iris._config.FrameBgTransparency
            entry.BorderSizePixel = 0
            entry.ZIndex = thisWidget.ZIndex + 1

            local key = Instance.new("TextLabel")
            key.Name = "Key"
            key.Size = UDim2.new(0.5, 0, 0, 0)
            key.AutomaticSize = Enum.AutomaticSize.Y
            key.BackgroundTransparency = 1
            key.BorderSizePixel = 0
            key.ZIndex = thisWidget.ZIndex + 2
            key.LayoutOrder = 2
            key.ClipsDescendants = true
            key.Parent = entry

            local value = Instance.new("TextBox")
            value.Name = "Value"
            value.Size = UDim2.new(0.5, 0, 0, 0)
            value.AutomaticSize = Enum.AutomaticSize.Y
            value.BackgroundColor3 = Iris._config.FrameBgColor
            value.BackgroundTransparency = 1
            value.BorderSizePixel = 0
            value.ZIndex = thisWidget.ZIndex + 2
            value.LayoutOrder = 2
            value.ClipsDescendants = true
            value.Parent = entry

            local seperator = Instance.new("Frame")
            seperator.Name = "Seperator"
            seperator.Size = UDim2.new(0, 1, 2, 0)
            seperator.Position = UDim2.new(1, 1, 0.5, 0)
            seperator.AnchorPoint = Vector2.new(0, 0.5)
            seperator.BackgroundColor3 = Iris._config.SeparatorColor
            seperator.BackgroundTransparency = Iris._config.SeparatorTransparency
            seperator.BorderSizePixel = 0
            seperator.ZIndex = thisWidget.ZIndex + 2
            seperator.LayoutOrder = 1
            seperator.Parent = key

            local padding = Instance.new("UIPadding")
            padding.Parent = entry

            widgets.UIListLayout(entry, Enum.FillDirection.Horizontal, UDim.new(0, 0))
            widgets.UIStroke(entry, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)

            widgets.applyTextStyle(key)
            widgets.applyTextStyle(value)

            widgets.applyFrameStyle(key)
            widgets.applyFrameStyle(value)

            widgets.UISizeConstraint(key, Vector2.new(1, 0))
            widgets.UISizeConstraint(value, Vector2.new(1, 0))

            entry.Parent = thisWidget.Instance

            return entry, key, value
        end

        local function getTableDescendants(tbl: { [number | string]: any }, parent: TableChild?)
            local nodes = {} :: { TableChild }
            local entries = {} :: { { key: string, value: any } }

            for key, value in pairs(tbl) do
                table.insert(entries, { key = key, value = value })
            end

            table.sort(entries, function(a, b)
                return a.key < b.key
            end)

            for _, entry in entries do
                local key = entry.key
                local value = entry.value

                local node = {
                    key = key,
                    value = value,
                    depth = parent and parent.depth + 1 or 0,
                    path = parent and `{parent.path}\1{key}` or key,
                    rawPath = parent and table.clone(parent.rawPath) or {},
                    parent = parent,
                } :: TableChild

                table.insert(node.rawPath, key)
                table.insert(nodes, node)

                if type(value) == "table" then
                    for _, descNode in getTableDescendants(value, node) do
                        table.insert(nodes, descNode)
                    end
                end
            end

            return nodes
        end

        local function refreshTableState(thisWidget: Types.Widget)
            local expanded = thisWidget.state.expanded:get() or {}
            local state = thisWidget.state.table:get() or {}

            local existing = {} :: { [string]: any }

            local descendantsByPath = {}
            local descendants = getTableDescendants(state)

            for _, child in thisWidget.Instance:GetChildren() do
                if child:IsA("Frame") or child:IsA("TextButton") then
                    existing[child.Name] = child
                end
            end

            for index, entry in ipairs(descendants) do
                local frame: Frame
                local input: TextBox

                local entryType = typeof(entry.value)
                local entryPadding = 4 + (entry.depth * 16)
                local existingChild = existing[entry.path]

                local isTable = entryType == "table"
                local isExpanded = not entry.parent or (expanded[entry.parent.path] and existing[entry.parent.path] and existing[entry.parent.path].Visible)

                if existingChild then
                    if isTable then
                        if not existingChild:GetAttribute("Table") then
                            existingChild:Destroy()
                            existingChild = nil
                        else
                            frame = existingChild
                        end
                    else
                        frame = existingChild
                        input = frame:FindFirstChild("Value")
                    end
                end

                if not existingChild then
                    local key

                    if isTable then
                        frame, key = createTableEntry(thisWidget, entry.path)
                        frame.Arrow.Image = if expanded[entry.path] then widgets.ICONS.DOWN_POINTING_TRIANGLE else widgets.ICONS.RIGHT_POINTING_TRIANGLE

                        frame.MouseButton1Click:Connect(function()
                            local expanded = thisWidget.state.expanded:get() or {}
                            local didExpand = not expanded[entry.path]

                            expanded[entry.path] = didExpand
                            frame.Arrow.Image = if didExpand then widgets.ICONS.DOWN_POINTING_TRIANGLE else widgets.ICONS.RIGHT_POINTING_TRIANGLE

                            thisWidget.state.expanded:set(expanded, true)
                        end)
                    else
                        frame, key, input = createInputEntry(thisWidget, entry.path)
                        input.FocusLost:Connect(function()
                            local state = thisWidget.state.table:get() or {}
                            local value = convertToValue(input.Text)

                            if value == nil then
                                input.Text = convertFromValue(entry.value)
                                return
                            else
                                local path = table.clone(entry.rawPath)
                                local node = state

                                if #path > 1 then
                                    while #path > 1 do
                                        node = node[table.remove(path, 1)]
                                    end

                                    node[path[1]] = value
                                elseif #path == 1 then
                                    state[path[1]] = value
                                else
                                    input.Text = convertFromValue(entry.value)
                                    return
                                end
                            end

                            thisWidget.lastTableChangedTick = Iris._cycleTick + 1
                            thisWidget.state.table:set(state, true)
                        end)
                    end

                    key.Text = convertFromValue(entry.key)
                end

                descendantsByPath[entry.path] = frame
                frame.LayoutOrder = index

                if entry.parent then
                    frame.Visible = isExpanded

                    if not frame.Visible then
                        continue
                    end
                end

                if not isTable then
                    entryPadding += 16
                    frame.Key.Size = UDim2.new(0.5, -entryPadding / 2, 0, 0)
                    frame.Value.Size = UDim2.new(0.5, entryPadding / 2, 0, 0)
                    frame.UIPadding.PaddingLeft = UDim.new(0, entryPadding)
                else
                    frame.UIPadding.PaddingLeft = UDim.new(0, entryPadding)
                end

                if input then
                    input.Text = convertFromValue(entry.value)
                end
            end

            for path, child in existing do
                if not descendantsByPath[path] then
                    child:Destroy()
                end
            end
        end
    
        --stylua: ignore
        Iris.WidgetConstructor("EditableTable", {
            hasState = true,
            hasChildren = false,
    
            Args = {
                ["Table"] = 1,
            },
            
            Events = {
                ["tableChanged"] = {
                    ["Init"] = function(_thisWidget: Types.Widget) end,
                    ["Get"] = function(thisWidget: Types.Widget)
                        return thisWidget.lastTableChangedTick == Iris._cycleTick
                    end,
                },

                ["hovered"] = widgets.EVENTS.hover(function(thisWidget: Types.Widget)
                    return thisWidget.Instance
                end), 
            },
            Generate = function(thisWidget: Types.Widget)
                Tables[thisWidget.ID] = thisWidget
    
                local Table: Frame = Instance.new("Frame")
                Table.Name = "Iris_EditableTable"
                Table.Size = UDim2.new(Iris._config.ItemWidth, UDim.new(0, 0))
                Table.AutomaticSize = Enum.AutomaticSize.Y
                Table.BackgroundTransparency = 1
                Table.BorderSizePixel = 0
                Table.ZIndex = thisWidget.ZIndex + 1024 -- allocate room for 1024 cells, because Table UIStroke has to appear above cell UIStroke
                Table.LayoutOrder = thisWidget.ZIndex
                Table.ClipsDescendants = true
    
                widgets.UIListLayout(Table, Enum.FillDirection.Vertical, UDim.new(0, 0))
                widgets.UIStroke(Table, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)
    
                return Table
            end,
            Update = function(thisWidget: Types.Widget)
            end,
            Discard = function(thisWidget: Types.Widget)
                Tables[thisWidget.ID] = nil
                thisWidget.Instance:Destroy()
            end,
            GenerateState = function(thisWidget: Types.Widget)
                thisWidget.state.expanded = Iris._widgetState(thisWidget, "expanded", {})

                if thisWidget.state.table == nil then
                    thisWidget.state.table = Iris._widgetState(thisWidget, "table", {})
                end
            end,
            UpdateState = function(thisWidget: Types.Widget)
                refreshTableState(thisWidget)
            end,
        } :: Types.WidgetClass )
    end


    --stylua: ignore
    Iris.WidgetConstructor("Table", {
        hasState = true,
        hasChildren = true,
        Args = {
            NumColumns = 1,
            Header = 2,
            RowBackground = 3,
            OuterBorders = 4,
            InnerBorders = 5
        },
        Events = {},
        Generate = function(thisWidget: Types.Table)
            Tables[thisWidget.ID] = thisWidget
            local Table: Frame = Instance.new("Frame")
            Table.Name = "Iris_Table"
            Table.AutomaticSize = Enum.AutomaticSize.Y
            Table.Size = UDim2.fromScale(1, 0)
            Table.BackgroundTransparency = 1
            Table.ZIndex = thisWidget.ZIndex
            Table.LayoutOrder = thisWidget.ZIndex

            local RowContainer: Frame = Instance.new("Frame")
            RowContainer.Name = "RowContainer"
            RowContainer.AutomaticSize = Enum.AutomaticSize.Y
            RowContainer.Size = UDim2.fromScale(1, 0)
            RowContainer.BackgroundTransparency = 1
            RowContainer.ZIndex = 1

            widgets.UIListLayout(RowContainer, Enum.FillDirection.Vertical, UDim.new())

            RowContainer.Parent = Table
			thisWidget.RowContainer = RowContainer

            local BorderContainer: Frame = Instance.new("Frame")
            BorderContainer.Name = "BorderContainer"
            BorderContainer.Size = UDim2.fromScale(1, 1)
            BorderContainer.BackgroundTransparency = 1
            BorderContainer.ZIndex = 2

            widgets.UIStroke(BorderContainer, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)

            BorderContainer.Parent = Table

            thisWidget.ColumnIndex = 1
            thisWidget.RowIndex = 1
            thisWidget.RowInstances = {}
            thisWidget.CellInstances = {}
            thisWidget.RowBorders = {}
            thisWidget.ColumnBorders = {}
            thisWidget.RowCycles = {}

            local callbackIndex: number = #Iris._postCycleCallbacks + 1
            local desiredCycleTick: number = Iris._cycleTick + 1
            Iris._postCycleCallbacks[callbackIndex] = function()
                if Iris._cycleTick >= desiredCycleTick then
                    if thisWidget.lastCycleTick ~= -1 then
                        thisWidget.state.widths.lastChangeTick = Iris._cycleTick
                        Iris._widgets["Table"].UpdateState(thisWidget)
                    end
                    Iris._postCycleCallbacks[callbackIndex] = nil
                end
            end

            return Table
        end,
        GenerateState = function(thisWidget: Types.Table)
            if thisWidget.state.widths == nil then
                local Widths: { UDim } = table.create(thisWidget.arguments.NumColumns, UDim.new(1 / thisWidget.arguments.NumColumns, 0))
                thisWidget.state.widths = Iris._widgetState(thisWidget, "widths", Widths)
            end

            local Table = thisWidget.Instance :: Frame
            local BorderContainer: Frame = Table.BorderContainer
            local Position: UDim = UDim.new()

            for index = 1, thisWidget.arguments.NumColumns do
                Position += thisWidget.state.widths.value[index]
                local Border = GenerateColumnBorder(thisWidget, index, "Light")
                Border.Position = UDim2.new(Position, UDim.new())
                Border.Visible = thisWidget.arguments.InnerBorders
                thisWidget.ColumnBorders[index] = Border
                Border.Parent = BorderContainer
            end
        end,
        Update = function(thisWidget: Types.Table)
            assert(thisWidget.arguments.NumColumns >= 1, "Iris.Table must have at least one column.")

            for rowIndex: number, row: Frame in thisWidget.RowInstances do
                if rowIndex == 0 then
                    row.BackgroundColor3 = Iris._config.TableHeaderColor
                    row.BackgroundTransparency = Iris._config.TableHeaderTransparency
                elseif thisWidget.arguments.RowBackground == true then
                    if (rowIndex % 2) == 0 then
                        row.BackgroundColor3 = Iris._config.TableRowBgAltColor
                        row.BackgroundTransparency = Iris._config.TableRowBgAltTransparency
                    else
                        row.BackgroundColor3 = Iris._config.TableRowBgColor
                        row.BackgroundTransparency = Iris._config.TableRowBgTransparency
                    end
                else
                    row.BackgroundTransparency = 1
                end
            end
            
            for rowIndex: number, Border: Frame in thisWidget.RowBorders do
                Border.Visible = thisWidget.arguments.InnerBorders
            end

            for _, Border: GuiButton in thisWidget.ColumnBorders do
                Border.Visible = thisWidget.arguments.InnerBorders
            end
            
            -- the header border visibility must be updated after settings all borders
            -- visiblity or not
            local HeaderRow: Frame? = thisWidget.RowInstances[0]
            local HeaderBorder: Frame? = thisWidget.RowBorders[0]
            if HeaderRow ~= nil then
                HeaderRow.Visible = thisWidget.arguments.Header
            end
            if HeaderBorder ~= nil then
                HeaderBorder.Visible = thisWidget.arguments.Header
            end

            local Table = thisWidget.Instance :: Frame
            local BorderContainer = Table.BorderContainer :: Frame
            BorderContainer.UIStroke.Enabled = thisWidget.arguments.OuterBorders
        end,
        UpdateState = function(thisWidget: Types.Table)
            local ColumnWidths = thisWidget.state.widths.value
            local TotalWidth: UDim = UDim.new()
            for index = 1, thisWidget.arguments.NumColumns do
                TotalWidth += ColumnWidths[index]
            end

            local Position: UDim = UDim.new()
            for index = 1, thisWidget.arguments.NumColumns do
                local Width: UDim = UDim.new(ColumnWidths[index].Scale, ColumnWidths[index].Offset - (ColumnWidths[index].Scale * TotalWidth.Offset))
                Position += Width
                thisWidget.ColumnBorders[index].Position = UDim2.new(Position, UDim.new())

                for _, row: { Frame } in thisWidget.CellInstances do
                    row[index].Size = UDim2.new(Width, UDim.new())
                end
            end
        end,
        ChildAdded = function(thisWidget: Types.Table, thisChild: Types.Widget)
            local rowIndex: number = thisWidget.RowIndex
            local columnIndex: number = thisWidget.ColumnIndex
            -- determine if the row exists yet
            local Row: Frame = thisWidget.RowInstances[rowIndex]
            thisWidget.RowCycles[rowIndex] = Iris._cycleTick

            if Row ~= nil then
                return thisWidget.CellInstances[rowIndex][columnIndex]
            end

            Row = GenerateRow(thisWidget, rowIndex)
            if rowIndex == 0 then
                Row.Visible = thisWidget.arguments.Header
            end
            Row.Parent = thisWidget.RowContainer

            if rowIndex > 0 then
                local Border = GenerateRowBorder(thisWidget, rowIndex - 1, if rowIndex == 1 then "Strong" else "Light")
                Border.Visible = thisWidget.arguments.InnerBorders and (if rowIndex == 1 then thisWidget.arguments.Header and (thisWidget.RowInstances[0] ~= nil) else true)
                thisWidget.RowBorders[rowIndex - 1] = Border
                Border.Parent = thisWidget.RowContainer
            end

            return thisWidget.CellInstances[rowIndex][columnIndex]
        end,
        Discard = function(thisWidget: Types.Table)
            Tables[thisWidget.ID] = nil
            thisWidget.Instance:Destroy()     
            widgets.discardState(thisWidget)       
        end
    } :: Types.WidgetClass)
end
