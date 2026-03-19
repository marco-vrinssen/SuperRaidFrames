-- categoryInfo fields from C_SpellDiminish are secret C-level values; == comparisons
-- work but table lookup does not, so each category is matched individually

hooksecurefunc(SpellDiminishStatusTrayItemMixin, "SetCategoryInfo", function(self, categoryInfo)
    local spellId
    if     categoryInfo.category == Enum.SpellDiminishCategory.Stun         then spellId = 408   -- Kidney Shot
    elseif categoryInfo.category == Enum.SpellDiminishCategory.Disorient    then spellId = 2094  -- Blind
    elseif categoryInfo.category == Enum.SpellDiminishCategory.Incapacitate then spellId = 118   -- Polymorph
    end
    if not spellId then return end

    local spellTexture = C_Spell.GetSpellTexture(spellId)
    if spellTexture then
        self.Icon:SetTexture(spellTexture)
    end
end)
