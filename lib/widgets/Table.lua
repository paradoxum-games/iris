local Types = require(script.Parent.Parent.Types)

return function(Iris: Types.Internal, widgets: Types.WidgetUtility)
    local tableWidgets: { [Types.ID]: Types.Widget } = {}

    -- reset the cell index every frame.
    table.insert(Iris._postCycleCallbacks, function()
        for _, thisWidget: Types.Widget in tableWidgets do
            thisWidget.RowColumnIndex = 0
        end
    end)

    -- Editable Table Widget
    do
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

        type TableChild = { key: string, depth: number, parent: any?, value: any }
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
                    parent = parent,
                } :: TableChild

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

                local isExpanded = not entry.parent or (expanded[entry.parent.path] and existing[entry.parent.path].Visible)
                local isTable = entryType == "table"

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
                        frame.Arrow.Image = if expanded[frame.Name] then widgets.ICONS.DOWN_POINTING_TRIANGLE else widgets.ICONS.RIGHT_POINTING_TRIANGLE

                        frame.MouseButton1Click:Connect(function()
                            local expanded = thisWidget.state.expanded:get() or {}
                            local didExpand = not expanded[frame.Name]

                            expanded[frame.Name] = didExpand
                            frame.Arrow.Image = if didExpand then widgets.ICONS.DOWN_POINTING_TRIANGLE else widgets.ICONS.RIGHT_POINTING_TRIANGLE

                            thisWidget.state.expanded:set(expanded)
                            refreshTableState(thisWidget)
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
                                local path = string.split(frame.Name, "\1")
                                local current = state

                                for i = 1, #path - 1 do
                                    current = current[path[i]]
                                end

                                current[path[#path]] = value
                            end

                            thisWidget.state.table:set(state)
                            thisWidget.lastTableChangedTick = Iris._cycleTick + 1

                            refreshTableState(thisWidget)
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
                tableWidgets[thisWidget.ID] = thisWidget
    
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
                tableWidgets[thisWidget.ID] = nil
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
        hasState = false,
        hasChildren = true,
        Args = {
            ["NumColumns"] = 1,
            ["RowBg"] = 2,
            ["BordersOuter"] = 3,
            ["BordersInner"] = 4,
        },
        Events = {
            ["hovered"] = widgets.EVENTS.hover(function(thisWidget: Types.Widget)
                return thisWidget.Instance
            end),
        },
        Generate = function(thisWidget: Types.Widget)
            tableWidgets[thisWidget.ID] = thisWidget

            thisWidget.InitialNumColumns = -1
            thisWidget.RowColumnIndex = 0
            -- reference to these is stored as an optimization
            thisWidget.ColumnInstances = {}
            thisWidget.CellInstances = {}

            local Table: Frame = Instance.new("Frame")
            Table.Name = "Iris_Table"
            Table.Size = UDim2.new(Iris._config.ItemWidth, UDim.new(0, 0))
            Table.AutomaticSize = Enum.AutomaticSize.Y
            Table.BackgroundTransparency = 1
            Table.BorderSizePixel = 0
            Table.ZIndex = thisWidget.ZIndex + 1024 -- allocate room for 1024 cells, because Table UIStroke has to appear above cell UIStroke
            Table.LayoutOrder = thisWidget.ZIndex
            Table.ClipsDescendants = true

            widgets.UIListLayout(Table, Enum.FillDirection.Horizontal, UDim.new(0, 0))
            widgets.UIStroke(Table, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)

            return Table
        end,
        Update = function(thisWidget: Types.Widget)
            local Table = thisWidget.Instance :: Frame

            if thisWidget.arguments.BordersOuter == false then
                Table.UIStroke.Thickness = 0
            else
                Table.UIStroke.Thickness = 1
            end

            if thisWidget.InitialNumColumns == -1 then
                if thisWidget.arguments.NumColumns == nil then
                    error("Iris.Table NumColumns argument is required", 5)
                end
                thisWidget.InitialNumColumns = thisWidget.arguments.NumColumns

                for index = 1, thisWidget.InitialNumColumns do
                    local zindex: number = thisWidget.ZIndex + 1 + index

                    local Column: Frame = Instance.new("Frame")
                    Column.Name = `Column_{index}`
                    Column.Size = UDim2.new(1 / thisWidget.InitialNumColumns, 0, 0, 0)
                    Column.AutomaticSize = Enum.AutomaticSize.Y
                    Column.BackgroundTransparency = 1
                    Column.BorderSizePixel = 0
                    Column.ZIndex = zindex
                    Column.LayoutOrder = zindex
                    Column.ClipsDescendants = true

                    widgets.UIListLayout(Column, Enum.FillDirection.Vertical, UDim.new(0, 0))

                    thisWidget.ColumnInstances[index] = Column
                    Column.Parent = Table
                end
            elseif thisWidget.arguments.NumColumns ~= thisWidget.InitialNumColumns then
                -- its possible to make it so that the NumColumns can increase,
                -- but decreasing it would interfere with child widget instances
                error("Iris.Table NumColumns Argument must be static")
            end

            if thisWidget.arguments.RowBg == false then
                for _, Cell: Frame in thisWidget.CellInstances do
                    Cell.BackgroundTransparency = 1
                end
            else
                for index: number, Cell: Frame in thisWidget.CellInstances do
                    local currentRow: number = math.ceil(index / thisWidget.InitialNumColumns)
                    Cell.BackgroundTransparency = if currentRow % 2 == 0 then Iris._config.TableRowBgAltTransparency else Iris._config.TableRowBgTransparency
                end
            end

            -- wooo, I love lua types. Especially on an object and child based system like Roblox! I never have to do anything
            -- annoying or dumb to make it like me!
            if thisWidget.arguments.BordersInner == false then
                for _, Cell: Frame & { UIStroke: UIStroke } in thisWidget.CellInstances :: any do
                    Cell.UIStroke.Thickness = 0
                end
            else
                for _, Cell: Frame & { UIStroke: UIStroke } in thisWidget.CellInstances :: any do
                    Cell.UIStroke.Thickness = 0.5
                end
            end
        end,
        Discard = function(thisWidget: Types.Widget)
            tableWidgets[thisWidget.ID] = nil
            thisWidget.Instance:Destroy()
        end,
        ChildAdded = function(thisWidget: Types.Widget)
            if thisWidget.RowColumnIndex == 0 then
                thisWidget.RowColumnIndex = 1
            end
            local potentialCellParent: Frame = thisWidget.CellInstances[thisWidget.RowColumnIndex]
            if potentialCellParent then
                return potentialCellParent
            end

            local selectedParent: Frame = thisWidget.ColumnInstances[((thisWidget.RowColumnIndex - 1) % thisWidget.InitialNumColumns) + 1]
            local zindex: number = selectedParent.ZIndex + thisWidget.RowColumnIndex

            local Cell: Frame = Instance.new("Frame")
            Cell.Name = `Cell_{thisWidget.RowColumnIndex}`
            Cell.Size = UDim2.new(1, 0, 0, 0)
            Cell.AutomaticSize = Enum.AutomaticSize.Y
            Cell.BackgroundTransparency = 1
            Cell.BorderSizePixel = 0
            Cell.ZIndex = zindex
            Cell.LayoutOrder = zindex
            Cell.ClipsDescendants = true

            widgets.UIPadding(Cell, Iris._config.CellPadding)
            widgets.UIListLayout(Cell, Enum.FillDirection.Vertical, UDim.new(0, Iris._config.ItemSpacing.Y))

            if thisWidget.arguments.BordersInner == false then
                widgets.UIStroke(Cell, 0, Iris._config.TableBorderLightColor, Iris._config.TableBorderLightTransparency)
            else
                widgets.UIStroke(Cell, 0.5, Iris._config.TableBorderLightColor, Iris._config.TableBorderLightTransparency)
                -- this takes advantage of unintended behavior when UIStroke is set to 0.5 to render cell borders,
                -- at 0.5, only the top and left side of the cell will be rendered with a border.
            end

            if thisWidget.arguments.RowBg ~= false then
                local currentRow: number = math.ceil(thisWidget.RowColumnIndex / thisWidget.InitialNumColumns)
                local color: Color3 = if currentRow % 2 == 0 then Iris._config.TableRowBgAltColor else Iris._config.TableRowBgColor
                local transparency: number = if currentRow % 2 == 0 then Iris._config.TableRowBgAltTransparency else Iris._config.TableRowBgTransparency

                Cell.BackgroundColor3 = color
                Cell.BackgroundTransparency = transparency
            end

            thisWidget.CellInstances[thisWidget.RowColumnIndex] = Cell
            Cell.Parent = selectedParent
            return Cell
        end,
    } :: Types.WidgetClass)
end
