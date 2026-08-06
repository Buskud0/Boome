-- Map select: create/rename/delete/start actions. Attaches methods to the MapSelect factory.

local MapStorage = require "core.storage.mapstorage"

return function(MapSelect)
    function MapSelect:start(name)
        self:close()
        if self.mode == "horde" then
            self.state.startHordeWith(name)
        else
            self.state.enterBuilderWith(name)
        end
        return true
    end

    function MapSelect:beginCreate()
        self.prompt = { kind = "create", buffer = "" }
    end

    function MapSelect:beginRename(name)
        self.prompt = { kind = "rename", map = name, buffer = name }
    end

    function MapSelect:beginDelete(name)
        self.confirm = { kind = "delete", map = name }
    end

    function MapSelect:submitPrompt()
        if self.prompt.kind == "create" then
            self:confirmCreate() else self:confirmRename() end
    end

    function MapSelect:confirmCreate()
        local name = self:cleanName(self.prompt.buffer)
        if not MapStorage.isValidName(name) then
            self.state.toast:show("Invalid name", 1.5)
            return
        end
        if MapStorage.mapExists(name) then
            self.state.toast:show("A map with that name exists", 1.5)
            return
        end
        local ok = MapStorage.saveMap(name, self.state.mapBuilder:grassFillData() or "")
        if not ok then
            self.state.toast:show("Save failed", 1.5)
            return
        end
        self.prompt = nil
        self:refreshList()
        self:start(name)
    end

    function MapSelect:confirmRename()
        local oldName = self.prompt.map
        local newName = self:cleanName(self.prompt.buffer)
        if not MapStorage.isValidName(newName) then
            self.state.toast:show("Invalid name", 1.5)
            return
        end
        if newName == oldName then
            self.prompt = nil
            return
        end
        if MapStorage.mapExists(newName) then
            self.state.toast:show("A map with that name exists", 1.5)
            return
        end
        if MapStorage.renameMap(oldName, newName) then
            if self.state.selectedMapName == oldName then self.state.selectedMapName = newName end
        else
            self.state.toast:show("Rename failed", 1.5)
        end
        self.prompt = nil
        self:refreshList()
    end

    function MapSelect:cleanName(buffer)
        return buffer:gsub("^%s+", ""):gsub("%s+$", "")
    end

    function MapSelect:acceptConfirm()
        if self.confirm and self.confirm.kind == "delete" then
            self:confirmDelete()
        end
    end

    function MapSelect:confirmDelete()
        local name = self.confirm.map
        MapStorage.deleteMap(name)
        self.confirm = nil
        self:refreshList()
    end
end
