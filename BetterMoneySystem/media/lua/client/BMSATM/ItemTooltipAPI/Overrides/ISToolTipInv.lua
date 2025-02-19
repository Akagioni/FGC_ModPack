local function NumberToDecimalString(value, _decimal)
    if not type(_decimal) == "number" then _decimal = 2 end
    return string.format("%.".._decimal.."f", value);
end

local function GetColorOrDefault(color, defaultColor)
    if type(color) ~= "table" then
        return defaultColor
    end
    if type(color.r) ~= "number" then color.r = defaultColor.r; end
    if type(color.g) ~= "number" then color.g = defaultColor.g; end
    if type(color.b) ~= "number" then color.b = defaultColor.b; end
    if type(color.a) ~= "number" then color.a = defaultColor.a; end
    return color
end

----------------------------------------------

---@param tooltip ObjectTooltip
---@param item InventoryItem
local function customDoTooltip(tooltip, fields, item)
    local font = tooltip:getFont()
    local lineSpacing = tooltip:getLineSpacing()
    local y = 5
    local itemName = item:getName()

    tooltip:render()
    tooltip:DrawText(font, itemName, 5.0, y, 1.0, 1.0, 0.8, 1.0);
    tooltip:adjustWidth(5, itemName)

    local height = y + lineSpacing + 5

    local extraX
    local extraY
    local inventoryItem

    --region Extra

    local extraItems = item:getExtraItems()
    if extraItems ~= nil then
        tooltip:DrawText(font, getText("Tooltip_item_Contains"), 5.0, height, 1.0, 1.0, 0.8, 1.0)
        extraX = 5 + TextManager.instance:MeasureStringX(font, getText("Tooltip_item_Contains")) + 4
        extraY = (lineSpacing - 10) / 2

        for i=0, extraItems:size()-1 do
            local extraItem = extraItems:get(i)
            inventoryItem = InventoryItemFactory.CreateItem(extraItem)
            tooltip:DrawTextureScaled(inventoryItem:getTex(), extraX, height + extraY, 10.0, 10.0, 1.0)
            extraX = extraX + 11
        end

        height = height + lineSpacing + 5
    end

    --endregion Extra

    --region Spices

    ---@type Food
    local food = item
    if instanceof(food, "Food") then
        local spices = food:getSpices()
        if spices ~= nil then
            tooltip:DrawText(font, getText("Tooltip_item_Spices"), 5.0, height, 1.0, 1.0, 0.8, 1.0)
            extraX = 5 + TextManager.instance:MeasureStringX(font, getText("Tooltip_item_Spices")) + 4
            extraY = (lineSpacing - 10) / 2

            for i=0, spices:size()-1 do
                local spice = spices:get(i)
                inventoryItem = InventoryItemFactory.CreateItem(spice)
                tooltip:DrawTextureScaled(inventoryItem:getTex(), extraX, height + extraY, 10.0, 10.0, 1.0)
                extraX = extraX + 11
            end

            height = height + lineSpacing + 5
        end
    end

    --endregion Spices

    --region CustomExtra

    local customExtras = {}
    for _, field in pairs(fields) do
        if field.fieldType == "extra" then
            local customExtra = {
                labelText = field.name,
                labelColor = field.result.labelColor,
                items = field.result.value,
            }
            if type(field.result.value) == "string" then
                customExtra.items = {field.result.value}
            end
            table.insert(customExtras, customExtra)
        end
    end

    local customExtraMaxWidth = 0
    if #customExtras > 0 then
        for i=1, #customExtras do
            local customExtra = customExtras[i]
            tooltip:DrawText(font, customExtra.labelText .. ":", 5.0, height, customExtra.labelColor.r, customExtra.labelColor.g, customExtra.labelColor.b, customExtra.labelColor.a)
            extraX = 5 + TextManager.instance:MeasureStringX(font, customExtra.labelText) + 6
            extraY = (lineSpacing - 10) / 2

            for i=1, #customExtra.items do
                local extra = customExtra.items[i]
                inventoryItem = InventoryItemFactory.CreateItem(extra)
                tooltip:DrawTextureScaled(inventoryItem:getTex(), extraX, height + extraY, 10.0, 10.0, 1.0)
                extraX = extraX + 11
                customExtraMaxWidth = math.max(customExtraMaxWidth, extraX)
            end

            height = height + lineSpacing + 5
        end
        customExtraMaxWidth = customExtraMaxWidth + 10
    end

    tooltip:setWidth(customExtraMaxWidth)

    --endregion

    --region Layout

    ---@type ObjectTooltip.Layout
    local layout = tooltip:beginLayout()
    layout:setMinLabelWidth(80)

    -- Weight
    local weightItem = layout:addItem();
    weightItem:setLabel(getText("Tooltip_item_Weight")..":", 1.0, 1.0, 0.8, 1.0);
    local weight = 0
    local cleanString = ""
    if not instanceof(item, "HandWeapon") and not instanceof(item, "Clothing") and not instanceof(item, "DrainableComboItem") then
        weight = item:getUnequippedWeight()
        if weight > 0.0 and weight < 0.01 then
            weight = 0.01
        end
        weightItem:setValueRightNoPlus(weight)
    elseif item:isEquipped() then
        cleanString = NumberToDecimalString(item:getEquippedWeight(), 2)
        weightItem:setValue(cleanString .. "    (" .. BMSATM.ItemTooltip.GetFloatString(item:getUnequippedWeight()) .. " " .. getText("Tooltip_item_Unequipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    elseif item:getAttachedSlot() > -1 then
        cleanString = NumberToDecimalString(item:getHotbarEquippedWeight(), 2)
        weightItem:setValue(cleanString .. "    (" .. BMSATM.ItemTooltip.GetFloatString(item:getUnequippedWeight()) .. " " .. getText("Tooltip_item_Unequipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    else
        cleanString = NumberToDecimalString(item:getUnequippedWeight(), 2)
        weightItem:setValue(cleanString .. "    (" .. BMSATM.ItemTooltip.GetFloatString(item:getUnequippedWeight()) .. " " .. getText("Tooltip_item_Equipped") .. ")", 1.0, 1.0, 1.0, 1.0)
    end

    -- Weight of stack
    local weightOfStack = tooltip:getWeightOfStack();
    if weightOfStack > 0.0 then
        local layoutItem = layout:addItem();
        layoutItem:setLabel(getText("Tooltip_item_StackWeight")..":", 1.0, 1.0, 0.8, 1.0);
        if weightOfStack > 0.0 and weightOfStack < 0.01 then
            weightOfStack = 0.01;
        end
        layoutItem:setValueRightNoPlus(weightOfStack);
    end

    -- Custom Fields
    for _, field in pairs(fields) do
        if field.fieldType ~= "extra" and field.result then
            ---@type ObjectTooltip.LayoutItem
            local layoutItem = layout:addItem()

            local color
            local labelColor
            if field.fieldType == "spacer" then
                layoutItem:setLabel("spacer", 0, 0, 0, 0)

            elseif field.fieldType == "label" then
                labelColor = GetColorOrDefault(field.result.labelColor, { r=1, g=1, b=1, a=1 })
                layoutItem:setLabel(field.result.value, labelColor.r, labelColor.g, labelColor.b, labelColor.a)

            elseif field.fieldType == "field" then
                labelColor = GetColorOrDefault(field.result.labelColor, { r=1, g=1, b=0.8, a=1 })
                color = GetColorOrDefault(field.result.color, { r=1, g=1, b=1, a=1 })
                layoutItem:setLabel(field.name..":", labelColor.r, labelColor.g, labelColor.b, labelColor.a)
                layoutItem:setValue(field.result.value, color.r, color.g, color.b, color.a)

            elseif field.fieldType == "progress" and type(field.result.value) == "number" then
                labelColor = GetColorOrDefault(field.result.labelColor, { r=1, g=1, b=0.8, a=1 })
                color = GetColorOrDefault(field.result.color, { r=0, g=0.6, b=0, a=0.7 })
                layoutItem:setLabel(field.name..":", labelColor.r, labelColor.g, labelColor.b, labelColor.a)
                layoutItem:setProgress(field.result.value, color.r, color.g, color.b, color.a)
            end
        end
    end

    -- Item Tooltip
    if item:getTooltip() ~= nil then
        local layoutItem = layout:addItem();
        layoutItem:setLabel(getText(item:getTooltip()), 1.0, 1.0, 0.8, 1.0);
    end

    --endregion Layout

    height = layout:render(5, height, tooltip)
    tooltip:endLayout(layout)

    height = height + 5
    tooltip:setHeight(height)

    if tooltip:getWidth() < 150.0 then
        tooltip:setWidth(150.0)
    end
end

--region ISToolTipInv:render

local original_ISToolTipInv_render = ISToolTipInv.render
function ISToolTipInv:render()

    local inventoryTooltip = BMSATM.ItemTooltip.GetTooltip(self.item:getFullType())

    if inventoryTooltip then
        if not ISContextMenu.instance or not ISContextMenu.instance.visibleCheck then

            -- Get fields with values
            for key in pairs(inventoryTooltip.fields) do
                inventoryTooltip.fields[key]:getValue(self.item)
            end

            local mx = getMouseX() + 24;
            local my = getMouseY() + 24;
            if not self.followMouse then
                mx = self:getX()
                my = self:getY()
                if self.anchorBottomLeft then
                    mx = self.anchorBottomLeft.x
                    my = self.anchorBottomLeft.y
                end
            end

            self.tooltip:setX(mx+11);
            self.tooltip:setY(my);

            self.tooltip:setWidth(50)
            self.tooltip:setMeasureOnly(true)
            customDoTooltip(self.tooltip, inventoryTooltip.fields, self.item)
            self.tooltip:setMeasureOnly(false);

            local myCore = getCore();
            local maxX = myCore:getScreenWidth();
            local maxY = myCore:getScreenHeight();

            local tw = self.tooltip:getWidth();
            local th = self.tooltip:getHeight();

            self.tooltip:setX(math.max(0, math.min(mx + 11, maxX - tw - 1)));
            if not self.followMouse and self.anchorBottomLeft then
                self.tooltip:setY(math.max(0, math.min(my - th, maxY - th - 1)));
            else
                self.tooltip:setY(math.max(0, math.min(my, maxY - th - 1)));
            end

            self:setX(self.tooltip:getX() - 11);
            self:setY(self.tooltip:getY());
            self:setWidth(tw + 11);
            self:setHeight(th);

            if self.followMouse then
                self:adjustPositionToAvoidOverlap({ x = mx - 24 * 2, y = my - 24 * 2, width = 24 * 2, height = 24 * 2 })
            end

            self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
            self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);

            customDoTooltip(self.tooltip, inventoryTooltip.fields, self.item)

        end
    else
        original_ISToolTipInv_render(self)
    end

end

--endregion ISToolTipInv:render
