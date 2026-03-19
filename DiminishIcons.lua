local iconOverrideByCategory = {
    [Enum.SpellDiminishCategory.Stun]         = 408,  -- Kidney Shot
    [Enum.SpellDiminishCategory.Disorient]    = 2094, -- Blind
    [Enum.SpellDiminishCategory.Incapacitate] = 118,  -- Polymorph
}

hooksecurefunc(SpellDiminishStatusTrayItemMixin, "SetCategoryInfo", function(self, categoryInfo)
    local spellId = iconOverrideByCategory[categoryInfo.category]
    if not spellId then return end

    local spellTexture = C_Spell.GetSpellTexture(spellId)
    if not spellTexture then return end

    self.Icon:SetTexture(spellTexture)
end)
