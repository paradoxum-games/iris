local Types = require(script.Parent.Parent.Types)

-- Tables need an overhaul.

return function(Iris: Types.Internal, widgets: Types.WidgetUtility)
    local tableWidgets: { [Types.ID]: Types.Table } = {}

    -- reset the cell index every frame.
    table.insert(Iris._postCycleCallbacks, function()
        for _, thisWidget: Types.Table in tableWidgets do
            thisWidget.RowColumnIndex = 0
        end
    end)

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

    --stylua: ignore
    Iris.WidgetConstructor("EditableTable", {
        hasState = true,
        hasChildren = false,

        Args = {
            ["Table"] = 1,
        },
        
        Events = {
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
            if thisWidget.state.table == nil then
                thisWidget.state.table = Iris._widgetState(thisWidget, "table", {})
            end
        end,
        UpdateState = function(thisWidget: Types.Widget)

            local refreshState

            refreshState = function()
                local existing = {}
                local currentTable = thisWidget.state.table:get() or {}
    
                for _, child: Types.Widget in thisWidget.Instance:GetChildren() do
                    if child:IsA("Frame") then
                        if currentTable[child.Name] == nil then
                            child:Destroy()
                        else
                            existing[child.Name] = child
                        end
                    end
                end
    
                local index = 1
                for name, obj in currentTable do
                    local frame: Frame
                    local input: TextBox

                    -- local canExpand = type(obj) == "table"

    
                    if existing[name] ~= nil then
                        frame = existing[name]
                        frame.LayoutOrder = index
                        input = frame.Value
                    else
                        local newObject = Instance.new("Frame")
                        newObject.Name = name
                        newObject.Size = UDim2.new(1, 0, 0, 0)
                        newObject.AutomaticSize = Enum.AutomaticSize.Y
                        newObject.BackgroundTransparency = 1
                        newObject.BorderSizePixel = 0
                        newObject.ZIndex = thisWidget.ZIndex + 1
                        newObject.LayoutOrder = index
    
                        widgets.UIListLayout(newObject, Enum.FillDirection.Horizontal, UDim.new(0, 0))
                        widgets.UIStroke(newObject, 1, Iris._config.TableBorderStrongColor, Iris._config.TableBorderStrongTransparency)
    
                        local nameInput = Instance.new("TextBox")
                        nameInput.Name = "Name"
                        nameInput.Size = UDim2.new(0.5, 0, 0, 0)
                        nameInput.AutomaticSize = Enum.AutomaticSize.Y
                        nameInput.BackgroundColor3 = Iris._config.FrameBgColor
                        nameInput.BackgroundTransparency = Iris._config.FrameBgTransparency
                        nameInput.BorderSizePixel = 0
                        nameInput.ZIndex = thisWidget.ZIndex + 2
                        nameInput.LayoutOrder = 2
                        nameInput.ClipsDescendants = true
                        nameInput.Text = tostring(name)
                        nameInput.Parent = newObject
    
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
                        seperator.Parent = nameInput
    
                        local valueInput = Instance.new("TextBox")
                        valueInput.Name = "Value"
                        valueInput.Size = UDim2.new(0.5, 0, 0, 0)
                        valueInput.AutomaticSize = Enum.AutomaticSize.Y
                        valueInput.BackgroundColor3 = Iris._config.FrameBgColor
                        valueInput.BackgroundTransparency = Iris._config.FrameBgTransparency
                        valueInput.BorderSizePixel = 0
                        valueInput.ZIndex = thisWidget.ZIndex + 2
                        valueInput.LayoutOrder = 2
                        valueInput.ClipsDescendants = true
                        valueInput.Parent = newObject
    
                        nameInput.FocusLost:Connect(function()
                            local tableValue = thisWidget.state.table:get()
                            local value = convertToValue(nameInput.Text)
    
                            if value == nil then
                                tableValue[newObject.Name] = nil
                            else
                                local current = tableValue[newObject.Name]
                                tableValue[newObject.Name] = nil
                                tableValue[value] = current
                                newObject.Name = value
                            end
    
                            thisWidget.state.table:set(tableValue)
                            refreshState()
                        end)
    
                        valueInput.FocusLost:Connect(function()
                            local value = convertToValue(valueInput.Text)
                            local tableValue = thisWidget.state.table:get()

                            tableValue[newObject.Name] = value
                            thisWidget.state.table:set(tableValue)

                            refreshState()
                        end)
    
                        widgets.applyTextStyle(nameInput)
                        widgets.applyTextStyle(valueInput)
    
                        widgets.applyFrameStyle(nameInput)
                        widgets.applyFrameStyle(valueInput)
    
                        widgets.UISizeConstraint(nameInput, Vector2.new(1, 0))
                        widgets.UISizeConstraint(valueInput, Vector2.new(1, 0))
    
                        newObject.Parent = thisWidget.Instance
    
                        input = valueInput
                        frame = newObject
                    end
    
                    frame.BackgroundTransparency = if index % 2 == 0 then Iris._config.TableRowBgAltTransparency else Iris._config.TableRowBgTransparency
                    input.Text = convertFromValue(obj)
                end
            end

            refreshState()
        end,
    } :: Types.WidgetClass )

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
        Generate = function(thisWidget: Types.Table)
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
        Update = function(thisWidget: Types.Table)
            local Table = thisWidget.Instance :: Frame

            if thisWidget.arguments.BordersOuter == false then
                Table.UIStroke.Thickness = 0
            else
                Table.UIStroke.Thickness = 1
            end

            if thisWidget.InitialNumColumns == -1 then
                if thisWidget.arguments.NumColumns == nil then
                    error("NumColumns argument is required for Iris.Table().", 5)
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
                error("NumColumns Argument must be static for Iris.Table().")
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
        Discard = function(thisWidget: Types.Table)
            tableWidgets[thisWidget.ID] = nil
            thisWidget.Instance:Destroy()
        end,
        ChildAdded = function(thisWidget: Types.Table, _thisChild: Types.Widget)
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
