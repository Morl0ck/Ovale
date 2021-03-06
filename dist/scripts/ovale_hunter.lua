local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_hunter_beast_mastery_pr"
    local desc = "[8.0] Simulationcraft: Hunter_Beast_Mastery_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Beast_Mastery".
#    class=hunter
#    spec=beast_mastery
#    talents=1303011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=beast_mastery)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=beast_mastery)

AddFunction BeastMasteryInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction BeastMasteryUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction BeastMasterySummonPet
{
 if pet.IsDead()
 {
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

### actions.default

AddFunction BeastMasteryDefaultMainActions
{
 #barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() Spell(barbed_shot)
 #multishot,if=spell_targets>2&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
 if Enemies() > 2 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } Spell(multishot_bm)
 #chimaera_shot
 Spell(chimaera_shot)
 #kill_command
 if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,if=pet.cat.buff.frenzy.down&charges_fractional>1.4|full_recharge_time<gcd.max|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and Charges(barbed_shot count=0) > 1.4 or SpellFullRecharge(barbed_shot) < GCD() or target.TimeToDie() < 9 Spell(barbed_shot)
 #multishot,if=spell_targets>1&(pet.cat.buff.beast_cleave.remains<gcd.max|pet.cat.buff.beast_cleave.down)
 if Enemies() > 1 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } Spell(multishot_bm)
 #cobra_shot,if=(active_enemies<2|cooldown.kill_command.remains>focus.time_to_max)&(buff.bestial_wrath.up&active_enemies>1|cooldown.kill_command.remains>1+gcd&cooldown.bestial_wrath.remains>focus.time_to_max|focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost)
 if { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { BuffPresent(bestial_wrath_buff) and Enemies() > 1 or SpellCooldown(kill_command) > 1 + GCD() and SpellCooldown(bestial_wrath) > TimeToMaxFocus() or Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) } Spell(cobra_shot)
}

AddFunction BeastMasteryDefaultMainPostConditions
{
}

AddFunction BeastMasteryDefaultShortCdActions
{
 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot)
 {
  #a_murder_of_crows
  Spell(a_murder_of_crows)
  #spitting_cobra
  Spell(spitting_cobra)
  #bestial_wrath,if=!buff.bestial_wrath.up
  if not BuffPresent(bestial_wrath_buff) Spell(bestial_wrath)
 }
}

AddFunction BeastMasteryDefaultShortCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or Enemies() > 2 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } and Spell(multishot_bm) or Spell(chimaera_shot) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and Charges(barbed_shot count=0) > 1.4 or SpellFullRecharge(barbed_shot) < GCD() or target.TimeToDie() < 9 } and Spell(barbed_shot) or Enemies() > 1 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } and Spell(multishot_bm) or { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { BuffPresent(bestial_wrath_buff) and Enemies() > 1 or SpellCooldown(kill_command) > 1 + GCD() and SpellCooldown(bestial_wrath) > TimeToMaxFocus() or Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) } and Spell(cobra_shot)
}

AddFunction BeastMasteryDefaultCdActions
{
 #auto_shot
 #counter_shot,if=equipped.sephuzs_secret&target.debuff.casting.react&cooldown.buff_sephuzs_secret.up&!buff.sephuzs_secret.up
 if HasEquippedItem(sephuzs_secret_item) and target.IsInterruptible() and not SpellCooldown(sephuzs_secret_buff) > 0 and not BuffPresent(sephuzs_secret_buff) BeastMasteryInterruptActions()
 #use_items
 BeastMasteryUseItemActions()
 #berserking,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(berserking)
 #blood_fury,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(blood_fury_ap)
 #ancestral_call,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(ancestral_call)
 #fireblood,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(fireblood)
 #lights_judgment
 Spell(lights_judgment)
 #potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up
 if BuffPresent(bestial_wrath_buff) and BuffPresent(aspect_of_the_wild_buff) and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or Spell(a_murder_of_crows) or Spell(spitting_cobra)
 {
  #stampede,if=buff.bestial_wrath.up|cooldown.bestial_wrath.remains<gcd|target.time_to_die<15
  if BuffPresent(bestial_wrath_buff) or SpellCooldown(bestial_wrath) < GCD() or target.TimeToDie() < 15 Spell(stampede)
  #aspect_of_the_wild
  Spell(aspect_of_the_wild)
 }
}

AddFunction BeastMasteryDefaultCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or Spell(a_murder_of_crows) or Spell(spitting_cobra) or not BuffPresent(bestial_wrath_buff) and Spell(bestial_wrath) or Enemies() > 2 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } and Spell(multishot_bm) or Spell(chimaera_shot) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and Charges(barbed_shot count=0) > 1.4 or SpellFullRecharge(barbed_shot) < GCD() or target.TimeToDie() < 9 } and Spell(barbed_shot) or Enemies() > 1 and { pet.BuffRemaining(pet_beast_cleave_buff) < GCD() or pet.BuffExpires(pet_beast_cleave_buff) } and Spell(multishot_bm) or { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { BuffPresent(bestial_wrath_buff) and Enemies() > 1 or SpellCooldown(kill_command) > 1 + GCD() and SpellCooldown(bestial_wrath) > TimeToMaxFocus() or Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) } and Spell(cobra_shot)
}

### actions.precombat

AddFunction BeastMasteryPrecombatMainActions
{
}

AddFunction BeastMasteryPrecombatMainPostConditions
{
}

AddFunction BeastMasteryPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 BeastMasterySummonPet()
}

AddFunction BeastMasteryPrecombatShortCdPostConditions
{
}

AddFunction BeastMasteryPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #aspect_of_the_wild
 Spell(aspect_of_the_wild)
}

AddFunction BeastMasteryPrecombatCdPostConditions
{
}

### BeastMastery icons.

AddCheckBox(opt_hunter_beast_mastery_aoe L(AOE) default specialization=beast_mastery)

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=shortcd specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatShortCdActions()
 unless not InCombat() and BeastMasteryPrecombatShortCdPostConditions()
 {
  BeastMasteryDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=shortcd specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatShortCdActions()
 unless not InCombat() and BeastMasteryPrecombatShortCdPostConditions()
 {
  BeastMasteryDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatMainActions()
 unless not InCombat() and BeastMasteryPrecombatMainPostConditions()
 {
  BeastMasteryDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=aoe specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatMainActions()
 unless not InCombat() and BeastMasteryPrecombatMainPostConditions()
 {
  BeastMasteryDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=cd specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatCdActions()
 unless not InCombat() and BeastMasteryPrecombatCdPostConditions()
 {
  BeastMasteryDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=cd specialization=beast_mastery
{
 if not InCombat() BeastMasteryPrecombatCdActions()
 unless not InCombat() and BeastMasteryPrecombatCdPostConditions()
 {
  BeastMasteryDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# ancestral_call
# aspect_of_the_wild
# aspect_of_the_wild_buff
# barbed_shot
# battle_potion_of_agility
# berserking
# bestial_wrath
# bestial_wrath_buff
# blood_fury_ap
# chimaera_shot
# cobra_shot
# counter_shot
# dire_beast
# fireblood
# kill_command
# lights_judgment
# multishot_bm
# pet_beast_cleave_buff
# pet_frenzy_buff
# quaking_palm
# revive_pet
# sephuzs_secret_buff
# sephuzs_secret_item
# spitting_cobra
# stampede
# war_stomp

    ]]
    OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
end
do
    local name = "sc_hunter_marksmanship_pr"
    local desc = "[8.0] Simulationcraft: Hunter_Marksmanship_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Marksmanship".
#    class=hunter
#    spec=marksmanship
#    talents=2103012

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=marksmanship)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=marksmanship)

AddFunction MarksmanshipInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction MarksmanshipUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.default

AddFunction MarksmanshipDefaultMainActions
{
 #hunters_mark,if=debuff.hunters_mark.down
 if target.DebuffExpires(hunters_mark_debuff) Spell(hunters_mark)
 #multishot,if=active_enemies>2&buff.precise_shots.up&cooldown.aimed_shot.full_recharge_time<gcd*buff.precise_shots.stack+action.aimed_shot.cast_time
 if Enemies() > 2 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) Spell(multishot_mm)
 #arcane_shot,if=active_enemies<3&buff.precise_shots.up&cooldown.aimed_shot.full_recharge_time<gcd*buff.precise_shots.stack+action.aimed_shot.cast_time
 if Enemies() < 3 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) Spell(arcane_shot)
 #aimed_shot,if=buff.precise_shots.down&buff.double_tap.down&(active_enemies>2&buff.trick_shots.up|active_enemies<3&full_recharge_time<cast_time+gcd)
 if BuffExpires(precise_shots_buff) and BuffExpires(double_tap_buff) and { Enemies() > 2 and BuffPresent(trick_shots_buff) or Enemies() < 3 and SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) + GCD() } Spell(aimed_shot)
 #rapid_fire,if=active_enemies<3|buff.trick_shots.up
 if Enemies() < 3 or BuffPresent(trick_shots_buff) Spell(rapid_fire)
 #multishot,if=active_enemies>2&buff.trick_shots.down
 if Enemies() > 2 and BuffExpires(trick_shots_buff) Spell(multishot_mm)
 #aimed_shot,if=buff.precise_shots.down&(focus>70|buff.steady_focus.down)
 if BuffExpires(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) } Spell(aimed_shot)
 #multishot,if=active_enemies>2&(focus>90|buff.precise_shots.up&(focus>70|buff.steady_focus.down&focus>45))
 if Enemies() > 2 and { Focus() > 90 or BuffPresent(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) and Focus() > 45 } } Spell(multishot_mm)
 #arcane_shot,if=active_enemies<3&(focus>70|buff.steady_focus.down&(focus>60|buff.precise_shots.up))
 if Enemies() < 3 and { Focus() > 70 or BuffExpires(steady_focus_buff) and { Focus() > 60 or BuffPresent(precise_shots_buff) } } Spell(arcane_shot)
 #serpent_sting,if=refreshable
 if target.Refreshable(serpent_sting_mm_debuff) Spell(serpent_sting_mm)
 #steady_shot
 Spell(steady_shot)
}

AddFunction MarksmanshipDefaultMainPostConditions
{
}

AddFunction MarksmanshipDefaultShortCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark)
 {
  #double_tap,if=cooldown.rapid_fire.remains<gcd
  if SpellCooldown(rapid_fire) < GCD() Spell(double_tap)
  #barrage,if=active_enemies>1
  if Enemies() > 1 Spell(barrage)
  #explosive_shot,if=active_enemies>1
  if Enemies() > 1 Spell(explosive_shot)

  unless Enemies() > 2 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(multishot_mm) or Enemies() < 3 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(arcane_shot) or BuffExpires(precise_shots_buff) and BuffExpires(double_tap_buff) and { Enemies() > 2 and BuffPresent(trick_shots_buff) or Enemies() < 3 and SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) + GCD() } and Spell(aimed_shot) or { Enemies() < 3 or BuffPresent(trick_shots_buff) } and Spell(rapid_fire)
  {
   #explosive_shot
   Spell(explosive_shot)
   #piercing_shot
   Spell(piercing_shot)
   #a_murder_of_crows
   Spell(a_murder_of_crows)
  }
 }
}

AddFunction MarksmanshipDefaultShortCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark) or Enemies() > 2 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(multishot_mm) or Enemies() < 3 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(arcane_shot) or BuffExpires(precise_shots_buff) and BuffExpires(double_tap_buff) and { Enemies() > 2 and BuffPresent(trick_shots_buff) or Enemies() < 3 and SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) + GCD() } and Spell(aimed_shot) or { Enemies() < 3 or BuffPresent(trick_shots_buff) } and Spell(rapid_fire) or Enemies() > 2 and BuffExpires(trick_shots_buff) and Spell(multishot_mm) or BuffExpires(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) } and Spell(aimed_shot) or Enemies() > 2 and { Focus() > 90 or BuffPresent(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) and Focus() > 45 } } and Spell(multishot_mm) or Enemies() < 3 and { Focus() > 70 or BuffExpires(steady_focus_buff) and { Focus() > 60 or BuffPresent(precise_shots_buff) } } and Spell(arcane_shot) or target.Refreshable(serpent_sting_mm_debuff) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

AddFunction MarksmanshipDefaultCdActions
{
 #auto_shot
 #counter_shot,if=equipped.sephuzs_secret&target.debuff.casting.react&cooldown.buff_sephuzs_secret.up&!buff.sephuzs_secret.up
 if HasEquippedItem(sephuzs_secret_item) and target.IsInterruptible() and not SpellCooldown(sephuzs_secret_buff) > 0 and not BuffPresent(sephuzs_secret_buff) MarksmanshipInterruptActions()
 #use_items
 MarksmanshipUseItemActions()

 unless target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark) or SpellCooldown(rapid_fire) < GCD() and Spell(double_tap)
 {
  #berserking,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(berserking)
  #blood_fury,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(blood_fury_ap)
  #ancestral_call,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(ancestral_call)
  #fireblood,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(fireblood)
  #lights_judgment
  Spell(lights_judgment)
  #potion,if=(buff.trueshot.react&buff.bloodlust.react)|((consumable.prolonged_power&target.time_to_die<62)|target.time_to_die<31)
  if { BuffPresent(trueshot_buff) and BuffPresent(burst_haste_buff any=1) or BuffPresent(prolonged_power_buff) and target.TimeToDie() < 62 or target.TimeToDie() < 31 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
  #trueshot,if=cooldown.aimed_shot.charges<1
  if SpellCharges(aimed_shot) < 1 Spell(trueshot)
 }
}

AddFunction MarksmanshipDefaultCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark) or SpellCooldown(rapid_fire) < GCD() and Spell(double_tap) or Enemies() > 1 and Spell(barrage) or Enemies() > 1 and Spell(explosive_shot) or Enemies() > 2 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(multishot_mm) or Enemies() < 3 and BuffPresent(precise_shots_buff) and SpellCooldown(aimed_shot) < GCD() * BuffStacks(precise_shots_buff) + CastTime(aimed_shot) and Spell(arcane_shot) or BuffExpires(precise_shots_buff) and BuffExpires(double_tap_buff) and { Enemies() > 2 and BuffPresent(trick_shots_buff) or Enemies() < 3 and SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) + GCD() } and Spell(aimed_shot) or { Enemies() < 3 or BuffPresent(trick_shots_buff) } and Spell(rapid_fire) or Spell(explosive_shot) or Spell(piercing_shot) or Spell(a_murder_of_crows) or Enemies() > 2 and BuffExpires(trick_shots_buff) and Spell(multishot_mm) or BuffExpires(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) } and Spell(aimed_shot) or Enemies() > 2 and { Focus() > 90 or BuffPresent(precise_shots_buff) and { Focus() > 70 or BuffExpires(steady_focus_buff) and Focus() > 45 } } and Spell(multishot_mm) or Enemies() < 3 and { Focus() > 70 or BuffExpires(steady_focus_buff) and { Focus() > 60 or BuffPresent(precise_shots_buff) } } and Spell(arcane_shot) or target.Refreshable(serpent_sting_mm_debuff) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

### actions.precombat

AddFunction MarksmanshipPrecombatMainActions
{
 #hunters_mark
 if target.DebuffExpires(hunters_mark_debuff) Spell(hunters_mark)
 #aimed_shot,if=active_enemies<3
 if Enemies() < 3 Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatMainPostConditions
{
}

AddFunction MarksmanshipPrecombatShortCdActions
{
 unless Spell(hunters_mark)
 {
  #double_tap,precast_time=5
  Spell(double_tap)

  unless Enemies() < 3 and Spell(aimed_shot)
  {
   #explosive_shot,if=active_enemies>2
   if Enemies() > 2 Spell(explosive_shot)
  }
 }
}

AddFunction MarksmanshipPrecombatShortCdPostConditions
{
 Spell(hunters_mark) or Enemies() < 3 and Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction MarksmanshipPrecombatCdPostConditions
{
 Spell(hunters_mark) or Spell(double_tap) or Enemies() < 3 and Spell(aimed_shot) or Enemies() > 2 and Spell(explosive_shot)
}

### Marksmanship icons.

AddCheckBox(opt_hunter_marksmanship_aoe L(AOE) default specialization=marksmanship)

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=shortcd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatShortCdActions()
 unless not InCombat() and MarksmanshipPrecombatShortCdPostConditions()
 {
  MarksmanshipDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=shortcd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatShortCdActions()
 unless not InCombat() and MarksmanshipPrecombatShortCdPostConditions()
 {
  MarksmanshipDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatMainActions()
 unless not InCombat() and MarksmanshipPrecombatMainPostConditions()
 {
  MarksmanshipDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=aoe specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatMainActions()
 unless not InCombat() and MarksmanshipPrecombatMainPostConditions()
 {
  MarksmanshipDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=cd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatCdActions()
 unless not InCombat() and MarksmanshipPrecombatCdPostConditions()
 {
  MarksmanshipDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=cd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatCdActions()
 unless not InCombat() and MarksmanshipPrecombatCdPostConditions()
 {
  MarksmanshipDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# aimed_shot
# ancestral_call
# arcane_shot
# barrage
# battle_potion_of_agility
# berserking
# blood_fury_ap
# counter_shot
# double_tap
# double_tap_buff
# explosive_shot
# fireblood
# hunters_mark
# hunters_mark_debuff
# lights_judgment
# multishot_mm
# piercing_shot
# precise_shots_buff
# prolonged_power_buff
# quaking_palm
# rapid_fire
# sephuzs_secret_buff
# sephuzs_secret_item
# serpent_sting_mm
# serpent_sting_mm_debuff
# steady_focus_buff
# steady_shot
# trick_shots_buff
# trueshot
# trueshot_buff
# war_stomp

    ]]
    OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
end
do
    local name = "sc_hunter_survival_pr"
    local desc = "[8.0] Simulationcraft: Hunter_Survival_PreRaid"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Survival".
#    class=hunter
#    spec=survival
#    talents=1101011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)


AddFunction can_gcd
{
 not Talent(mongoose_bite_talent) or BuffExpires(mongoose_fury_buff) or BuffRemaining(mongoose_fury_buff) - { BuffRemaining(mongoose_fury_buff) * FocusRegenRate() + Focus() } / PowerCost(mongoose_bite) * GCD() > GCD()
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=survival)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=survival)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=survival)
AddCheckBox(opt_harpoon SpellName(harpoon) default specialization=survival)

AddFunction SurvivalInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(muzzle) and target.IsInterruptible() Spell(muzzle)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction SurvivalUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction SurvivalSummonPet
{
 if pet.IsDead()
 {
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

AddFunction SurvivalGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(raptor_strike)
 {
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.default

AddFunction SurvivalDefaultMainActions
{
 #chakrams,if=active_enemies>1
 if Enemies() > 1 Spell(chakrams)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&buff.tip_of_the_spear.stack<3&active_enemies<2
 if Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Enemies() < 2 Spell(kill_command_sv)
 #wildfire_bomb,if=(focus+cast_regen<focus.max|active_enemies>1)&(dot.wildfire_bomb.refreshable&buff.mongoose_fury.down|full_recharge_time<gcd)
 if { Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or Enemies() > 1 } and { target.DebuffRefreshable(wildfire_bomb_debuff) and BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < GCD() } Spell(wildfire_bomb)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max&buff.tip_of_the_spear.stack<3
 if Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 Spell(kill_command_sv)
 #butchery,if=(!talent.wildfire_infusion.enabled|full_recharge_time<gcd)&active_enemies>3|(dot.shrapnel_bomb.ticking&dot.internal_bleeding.stack<3)
 if { not Talent(wildfire_infusion_talent) or SpellFullRecharge(butchery) < GCD() } and Enemies() > 3 or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 Spell(butchery)
 #serpent_sting,if=(active_enemies<2&refreshable&(buff.mongoose_fury.down|(variable.can_gcd&!talent.vipers_venom.enabled)))|buff.vipers_venom.up
 if Enemies() < 2 and target.Refreshable(serpent_sting_sv_debuff) and { BuffExpires(mongoose_fury_buff) or can_gcd() and not Talent(vipers_venom_talent) } or BuffPresent(vipers_venom_buff) Spell(serpent_sting_sv)
 #carve,if=active_enemies>2&(active_enemies<6&active_enemies+gcd<cooldown.wildfire_bomb.remains|5+gcd<cooldown.wildfire_bomb.remains)
 if Enemies() > 2 and { Enemies() < 6 and Enemies() + GCD() < SpellCooldown(wildfire_bomb) or 5 + GCD() < SpellCooldown(wildfire_bomb) } Spell(carve)
 #harpoon,if=talent.terms_of_engagement.enabled
 if Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #chakrams
 Spell(chakrams)
 #serpent_sting,target_if=min:remains,if=refreshable&buff.mongoose_fury.down|buff.vipers_venom.up
 if target.Refreshable(serpent_sting_sv_debuff) and BuffExpires(mongoose_fury_buff) or BuffPresent(vipers_venom_buff) Spell(serpent_sting_sv)
 #mongoose_bite_eagle,target_if=min:dot.internal_bleeding.stack,if=buff.mongoose_fury.up|focus>60
 if BuffPresent(mongoose_fury_buff) or Focus() > 60 Spell(mongoose_bite)
 #mongoose_bite,target_if=min:dot.internal_bleeding.stack,if=buff.mongoose_fury.up|focus>60
 if BuffPresent(mongoose_fury_buff) or Focus() > 60 Spell(mongoose_bite)
 #raptor_strike_eagle,target_if=min:dot.internal_bleeding.stack
 Spell(raptor_strike)
 #raptor_strike,target_if=min:dot.internal_bleeding.stack
 Spell(raptor_strike)
}

AddFunction SurvivalDefaultMainPostConditions
{
}

AddFunction SurvivalDefaultShortCdActions
{
 #auto_attack
 SurvivalGetInMeleeRange()
 #variable,name=can_gcd,value=!talent.mongoose_bite.enabled|buff.mongoose_fury.down|(buff.mongoose_fury.remains-(((buff.mongoose_fury.remains*focus.regen+focus)%action.mongoose_bite.cost)*gcd.max)>gcd.max)
 #steel_trap
 Spell(steel_trap)
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless Enemies() > 1 and Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Enemies() < 2 and Spell(kill_command_sv) or { Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or Enemies() > 1 } and { target.DebuffRefreshable(wildfire_bomb_debuff) and BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Spell(kill_command_sv) or { { not Talent(wildfire_infusion_talent) or SpellFullRecharge(butchery) < GCD() } and Enemies() > 3 or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or { Enemies() < 2 and target.Refreshable(serpent_sting_sv_debuff) and { BuffExpires(mongoose_fury_buff) or can_gcd() and not Talent(vipers_venom_talent) } or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv) or Enemies() > 2 and { Enemies() < 6 and Enemies() + GCD() < SpellCooldown(wildfire_bomb) or 5 + GCD() < SpellCooldown(wildfire_bomb) } and Spell(carve) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon)
 {
  #flanking_strike
  Spell(flanking_strike)

  unless Spell(chakrams) or { target.Refreshable(serpent_sting_sv_debuff) and BuffExpires(mongoose_fury_buff) or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv)
  {
   #aspect_of_the_eagle,if=target.distance>=6
   if target.Distance() >= 6 Spell(aspect_of_the_eagle)
  }
 }
}

AddFunction SurvivalDefaultShortCdPostConditions
{
 Enemies() > 1 and Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Enemies() < 2 and Spell(kill_command_sv) or { Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or Enemies() > 1 } and { target.DebuffRefreshable(wildfire_bomb_debuff) and BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Spell(kill_command_sv) or { { not Talent(wildfire_infusion_talent) or SpellFullRecharge(butchery) < GCD() } and Enemies() > 3 or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or { Enemies() < 2 and target.Refreshable(serpent_sting_sv_debuff) and { BuffExpires(mongoose_fury_buff) or can_gcd() and not Talent(vipers_venom_talent) } or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv) or Enemies() > 2 and { Enemies() < 6 and Enemies() + GCD() < SpellCooldown(wildfire_bomb) or 5 + GCD() < SpellCooldown(wildfire_bomb) } and Spell(carve) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Spell(chakrams) or { target.Refreshable(serpent_sting_sv_debuff) and BuffExpires(mongoose_fury_buff) or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or Spell(raptor_strike) or Spell(raptor_strike)
}

AddFunction SurvivalDefaultCdActions
{
 #muzzle,if=equipped.sephuzs_secret&target.debuff.casting.react&cooldown.buff_sephuzs_secret.up&!buff.sephuzs_secret.up
 if HasEquippedItem(sephuzs_secret_item) and target.IsInterruptible() and not SpellCooldown(sephuzs_secret_buff) > 0 and not BuffPresent(sephuzs_secret_buff) SurvivalInterruptActions()
 #use_items
 SurvivalUseItemActions()
 #berserking,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(berserking)
 #blood_fury,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(blood_fury_ap)
 #ancestral_call,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(ancestral_call)
 #fireblood,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(fireblood)
 #lights_judgment
 Spell(lights_judgment)
 #arcane_torrent,if=cooldown.kill_command.remains>gcd.max&focus<=30
 if SpellCooldown(kill_command_sv) > GCD() and Focus() <= 30 Spell(arcane_torrent_focus)
 #potion,if=buff.coordinated_assault.up&(buff.berserking.up|buff.blood_fury.up|!race.troll&!race.orc)
 if BuffPresent(coordinated_assault_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_ap_buff) or not Race(Troll) and not Race(Orc) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless Spell(steel_trap) or Spell(a_murder_of_crows)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalDefaultCdPostConditions
{
 Spell(steel_trap) or Spell(a_murder_of_crows) or Enemies() > 1 and Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Enemies() < 2 and Spell(kill_command_sv) or { Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or Enemies() > 1 } and { target.DebuffRefreshable(wildfire_bomb_debuff) and BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_sv) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and Spell(kill_command_sv) or { { not Talent(wildfire_infusion_talent) or SpellFullRecharge(butchery) < GCD() } and Enemies() > 3 or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or { Enemies() < 2 and target.Refreshable(serpent_sting_sv_debuff) and { BuffExpires(mongoose_fury_buff) or can_gcd() and not Talent(vipers_venom_talent) } or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv) or Enemies() > 2 and { Enemies() < 6 and Enemies() + GCD() < SpellCooldown(wildfire_bomb) or 5 + GCD() < SpellCooldown(wildfire_bomb) } and Spell(carve) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Spell(flanking_strike) or Spell(chakrams) or { target.Refreshable(serpent_sting_sv_debuff) and BuffExpires(mongoose_fury_buff) or BuffPresent(vipers_venom_buff) } and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or Spell(raptor_strike) or Spell(raptor_strike)
}

### actions.precombat

AddFunction SurvivalPrecombatMainActions
{
 #harpoon
 if CheckBoxOn(opt_harpoon) Spell(harpoon)
}

AddFunction SurvivalPrecombatMainPostConditions
{
}

AddFunction SurvivalPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 SurvivalSummonPet()
 #steel_trap
 Spell(steel_trap)
}

AddFunction SurvivalPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_harpoon) and Spell(harpoon)
}

AddFunction SurvivalPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction SurvivalPrecombatCdPostConditions
{
 Spell(steel_trap) or CheckBoxOn(opt_harpoon) and Spell(harpoon)
}

### Survival icons.

AddCheckBox(opt_hunter_survival_aoe L(AOE) default specialization=survival)

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=shortcd specialization=survival
{
 if not InCombat() SurvivalPrecombatShortCdActions()
 unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
 {
  SurvivalDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=shortcd specialization=survival
{
 if not InCombat() SurvivalPrecombatShortCdActions()
 unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
 {
  SurvivalDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=survival
{
 if not InCombat() SurvivalPrecombatMainActions()
 unless not InCombat() and SurvivalPrecombatMainPostConditions()
 {
  SurvivalDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=aoe specialization=survival
{
 if not InCombat() SurvivalPrecombatMainActions()
 unless not InCombat() and SurvivalPrecombatMainPostConditions()
 {
  SurvivalDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=cd specialization=survival
{
 if not InCombat() SurvivalPrecombatCdActions()
 unless not InCombat() and SurvivalPrecombatCdPostConditions()
 {
  SurvivalDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=cd specialization=survival
{
 if not InCombat() SurvivalPrecombatCdActions()
 unless not InCombat() and SurvivalPrecombatCdPostConditions()
 {
  SurvivalDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# ancestral_call
# arcane_torrent_focus
# aspect_of_the_eagle
# battle_potion_of_agility
# berserking
# berserking_buff
# blood_fury_ap
# blood_fury_ap_buff
# butchery
# carve
# chakrams
# coordinated_assault
# coordinated_assault_buff
# fireblood
# flanking_strike
# harpoon
# internal_bleeding_debuff
# kill_command_sv
# lights_judgment
# mongoose_bite
# mongoose_bite_talent
# mongoose_fury_buff
# muzzle
# quaking_palm
# raptor_strike
# revive_pet
# sephuzs_secret_buff
# sephuzs_secret_item
# serpent_sting_sv
# serpent_sting_sv_debuff
# shrapnel_bomb_debuff
# steel_trap
# terms_of_engagement_talent
# tip_of_the_spear_buff
# vipers_venom_buff
# vipers_venom_talent
# war_stomp
# wildfire_bomb
# wildfire_bomb_debuff
# wildfire_infusion_talent

    ]]
    OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
end
