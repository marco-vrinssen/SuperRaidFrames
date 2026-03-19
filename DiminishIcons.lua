local iconOverrideByCategory = {
    [Enum.SpellDiminishCategory.Stun]         = 408,  -- Kidney Shot
    [Enum.SpellDiminishCategory.Disorient]    = 2094, -- Blind
    [Enum.SpellDiminishCategory.Incapacitate] = 118,  -- Polymorph
}

hooksecurefunc(SpellDiminishStatusTrayItemMixin, "SetCategoryInfo", function(self, categoryInfo)
    -- categoryInfo.category is a secret C-level value and cannot be used as a table key,
    -- so use equality comparisons instead of table lookup
    local spellId
    if categoryInfo.category == Enum.SpellDiminishCategory.Stun then
        spellId = 408
    elseif categoryInfo.category == Enum.SpellDiminishCategory.Disorient then
        spellId = 2094
    elseif categoryInfo.category == Enum.SpellDiminishCategory.Incapacitate then
        spellId = 118
    end
    if not spellId then return end

    local spellTexture = C_Spell.GetSpellTexture(spellId)
    if not spellTexture then return end

    self.Icon:SetTexture(spellTexture)
end)
