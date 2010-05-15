-- ToME - Tales of Middle-Earth
-- Copyright (C) 2009, 2010 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

-- The far east on Arda

quickEntity('w', {show_tooltip=true, name='Sun Wall', display='^', color=colors.GOLD, image="terrain/mountain.png", block_move=true})
quickEntity('=', {show_tooltip=true, name='the great sea', display='~', color=colors.BLUE, image="terrain/river.png", block_move=true})
quickEntity(' ', {show_tooltip=true, name='plains', display='.', color=colors.LIGHT_GREEN, image="terrain/grass.png", can_encounter=true, equilibrium_level=-10})
quickEntity('~', {show_tooltip=true, name='river', display='~', color={r=0, g=80, b=255}, image="terrain/river.png", can_encounter=true, equilibrium_level=-10})
quickEntity('s', {show_tooltip=true, name='desert', display='.', color={r=203,g=189,b=72}, image="terrain/sand.png", can_encounter=true, equilibrium_level=-10})
quickEntity('t', {show_tooltip=true, name='forest', display='#', color=colors.LIGHT_GREEN, image="terrain/tree.png", block_move=true})
quickEntity('m', {show_tooltip=true, name='mountains', display='^', color=colors.UMBER, image="terrain/mountain.png", block_move=true})
quickEntity('h', {show_tooltip=true, name='low hills', display='^', color=colors.GREEN, image="terrain/hills.png", can_encounter=true, equilibrium_level=-10})

--quickEntity('A', {show_tooltip=true, name="Caves below the tower of Amon Sûl", 	display='>', color={r=0, g=255, b=255}, notice = true, change_level=1, change_zone="tower-amon-sul"})

--quickEntity('1', {show_tooltip=true, name="Bree (Town)", desc="A quiet town at the crossroads of the north", display='*', color={r=255, g=255, b=255}, image="terrain/town1.png", notice = true, change_level=1, change_zone="town-bree"})
--quickEntity('2', {show_tooltip=true, name="Minas Tirith (Town)", desc="Captical city of the Reunited-Kingdom and Gondor ruled by High King Eldarion", display='*', color={r=255, g=255, b=255}, image="terrain/town1.png", notice = true, change_level=1, change_zone="town-minas-tirith"})

-- Load encounters for this map
--[[
prepareEntitiesList("encounters", "mod.class.Encounter", "/data/general/encounters/arda-fareast.lua")
addData{ encounters = {
	chance=function(who)
		local harmless_chance = 1 + who:getLck(7)
		local hostile_chance = 5
		print("chance", hostile_chance, harmless_chance)
		if rng.percent(hostile_chance) then return "hostile"
		elseif rng.percent(harmless_chance) then return "harmless"
		end
	end}
}
]]

return [[
=================================================================================
=================================================================================
===========       ========================    ===================================
========             ===================       ==================================
=======               ================          =================================
=====                 ================              =============================
====                  ===============                 ===========================
===                    ==========               hh    ===========================
==t  tttt           =============           hhhhhh          =====================
==t ttttt         ~==  ==========           hhhhh                ================
==ttttttt         ~    ===========                              =================
==ttttttt        ~~    ==========~~~                            =================
==ttttttt       ~~     ===  ===    ~~~                         ==================
==ttttt         ~       =            ~~~~~~                   ===================
===tt           ~                         ~~~                   =================
====            ~~~                                  tt            ==============
=====             ~~~~                             ttt              =============
======               ~                           tttt                  ==========
=======              ~~                       tttttt                    =========
========              ~~                     tttttt                      ========
=========     hhh      ~~ tt       ttttttt   tttttt             hh        =======
==========   hhhh       ~~ tttttttttttttmmmmmtttttt           hhh         =======
==========   hhhh        ~~ttttttttttttmmmmmmmmttttt        hhhhh         =======
=========    hhh          ~~ttttttttttmmmmmmmmmmtttt        hhh           =======
=========                  ~ttttttttttmmmmmmmmmmttt                      ========
========                ~~~~~~~~tttttt~~mmmmmmmmttt                     =========
=======              ~~~~      ~~~~~~~~ttmmmmmmmtttt                   ==========
======            ~~~~             tttttttmmmmmmtttt                   ==========
=====           ~~~                ttttttmmmmmmttttt                  ===========
=====        ~~~~                    ttttmmmmttttttt               w  ===========
====~~~~~~~~~~                         mmmmtttttttt               www============
=====                                  mmtttttttt                 www============
=====                                                             www============
=====                                                             www============
======                                                            www============
========          =======              hhhhhh                     Mww============
==============================       hhhhhhh                      www============
================================         h                        www============
=================================                  hh             www============
=================================                  hhh            www============
=================================tttt             hhhh            www============
================================tttttttt          hh               w  ===========
================================tttttttttt                            ===========
================================ttttttttttt                            ==========
===============================stttttttttttt                sssssss    ==========
==============================sstssstttttttt            sssssssssssssss==========
=============================sstssttsst            ssssssssssssssssssss==========
=============================ssssssssssssssssssssssssssssssssssssssssss==========
=============================sssssssssssssssssssssssssssssssssssssssss===========
=============================ssssssssssssssssssssssssssssssssssstssss============
=============================sssssssssssssssssssssssssssssssssssssss=============
==============================sssssssssstssssssssssssssssssssssssss==============
==============================ssssssssssssssssssssssssstssssssssss===============
================================sssssssssssssssssssssssssssssssss================
===================================ssssssssssssssssssss==========================
============================================sssssss==============================
=================================================================================]]
