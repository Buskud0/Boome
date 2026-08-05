-- Map builder: undo/redo history. Attaches methods to the MapBuilder factory.

return function(MapBuilder)
    function MapBuilder:undo()
        local action = self:popAction(self.undoStack)
        if not action then return end

        local inverseType = self:getInverseActionType(action.type)
        self:applyAction(inverseType, action)
        self:pushAction(self.redoStack, inverseType, action)

        self.hasUnsavedChanges = true
        self.state.toast:show("Undo", 1)
    end

    function MapBuilder:redo()
        local action = self:popAction(self.redoStack)
        if not action then return end

        self:applyAction(action.type, action)
        self:pushAction(self.undoStack, action.type, action)

        self.hasUnsavedChanges = true
        self.state.toast:show("Redo", 1)
    end

    function MapBuilder:popAction(stack)
        local action = stack[#stack]
        if action then table.remove(stack) end
        return action
    end

    function MapBuilder:pushAction(stack, actionType, action)
        table.insert(stack, { type = actionType, col = action.col, row = action.row, material = action.material })
    end

    function MapBuilder:getInverseActionType(actionType)
        if actionType:find("_place", 1, true) then
            return actionType:gsub("_place$", "_remove")
        end
        return actionType:gsub("_remove$", "_place")
    end

    function MapBuilder:applyAction(actionType, action)
        if actionType:find("_remove", 1, true) then
            self:removePlacedRecord(actionType, action)
        else
            self:reinsertPlacedRecord(actionType, action)
        end
    end

    function MapBuilder:removePlacedRecord(actionType, action)
        local records = self:getRecordsForAction(actionType)
        for i = #records, 1, -1 do
            if records[i].col == action.col and records[i].row == action.row then
                table.remove(records, i)
                break
            end
        end
        self.state.grid:rebuildGrid()
    end

    function MapBuilder:reinsertPlacedRecord(actionType, action)
        local placeFn = self:getPlaceFnForAction(actionType)
        placeFn(self.state.grid, action.col, action.row, action.material)
    end

    function MapBuilder:getRecordsForAction(actionType)
        if actionType:find("block", 1, true) then return self.state.grid.blockRecords end
        return self.state.grid.objectRecords
    end

    function MapBuilder:getPlaceFnForAction(actionType)
        if actionType:find("block", 1, true) then return self.state.grid.placeBlock end
        return self.state.grid.placeObject
    end

    function MapBuilder:revert()
        if not self.hasUnsavedChanges or not self.hasSavedFile then return end
        self:load()
        self:resetHistory()
        self.state.toast:show("Reverted", 1)
    end
end