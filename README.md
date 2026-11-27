# Bastion Professions

Shopping lists **with quantities**, pushed straight into Auctionator.

Auctionator 2.6.3 has no import and its shopping lists store item *names* only,
with no counts. This addon keeps the counts and writes the names across.

## Commands

| Command | What it does |
|---|---|
| `/mats` | What you still need, counting your bags |
| `/mats push` | Build the Auctionator shopping list |
| `/mats push all` | Include vendor and self-crafted items too |
| `/mats show` | Print the full list with quantities |
| `/mats clear` | Delete the Auctionator list again |

`/shoplist` works as an alias.

After `/mats push`, open the auction house, go to the **Shopping** tab and pick
**Engineering 1-450** from the dropdown. The old "Engineering 1-405" list is
removed automatically. If the AH was already open, reselect it
from the dropdown to see the new contents.

## What gets left out, and why

`/mats push` sends the 29 auction house items. The other 5 are skipped because
buying them there is a mistake:

- **Weak Flux, Mining Pick, Skinning Knife, Blacksmith Hammer** are vendor
  goods costing coppers. They are rarely even listed.
- **Fel Iron Casing** is made by you, from Fel Iron Bars already on this list.
  Buying it means paying twice.

`/mats push all` overrides this.

## Adding your own lists

Edit `Lists.lua`. Each row is `{ "Item Name", quantity, source }` where source is
`"ah"`, `"vendor"` or `"craft"`. Item names must match the game exactly.

## Tests

`lua tests/shopping_list.lua` runs the addon against a stubbed client and a
stubbed Auctionator. `tests/plan.lua` checks the route and the list against
each other, `tests/level.lua` drives the button.

## /mats level

A button that crafts the next thing on the Engineering 1-450 route, and
retargets itself as your skill rises. Sit at the trainer, click, keep
clicking; it changes what it is pointing at on its own.

```
/mats level            put the button up, bound to SHIFT-W
/mats level plan       print the whole route, marked where you are
/mats level key ALT-E  bind it to something else
/mats level next       skip a step, same as shift-clicking it
/mats level auto       back to following your skill, same as ctrl-click
/mats level off        hide it and release the key
```

### Skipping a step

**Shift-click** moves to the next step, **ctrl-click** goes back to following
your skill. Both have slash equivalents.

The skill number is the right default and needs no input, but a step can be
unusable for reasons it cannot see: the recipe is a reputation reward you do
not have, or its reagents cost more than the next step's.

A skip is a nudge, not a mode. It holds a later step than your skill implies,
and **clears itself the moment your skill catches up** to it, so it cannot
become a setting you forget you changed and then wonder why the button is
wrong all evening. While it is active the label says `skipped`.

A skipped step batches from where the step *begins*, not from your skill.
Measuring from your skill would queue the whole gap you just jumped over:
sitting at skill 1 on a step that runs 55-58 would ask for 57 crafts instead
of 3.

### It queues what could finish the step

On Warmane every skill-up is **+3** (your chat log: 1, 4, 7, 10, one craft
each; the guide's counts assume it too). So `(step.to - skill) / 3` crafts,
rounded up, is the most that can still be useful: if every one of them skills
up, the step is done. That is the batch, capped again by how many your reagents
allow.

So at 1/40 it queues 13, at 37/40 it queues 1, and with mats for only 4 it
queues 4. When yellow or green crafts miss, the next click queues the rest.
The first version assumed +1 and queued three times too many, so the tail of
every batch kept crafting after the step was done.

### It stops you at the trainer

At 75, 150, 225, 300 and 375 nothing gains skill until you train the next
rank, so the button says `train: Journeyman Engineering (from 50)` and so on
instead of crafting. Grand Master is trained in Northrend.

### It makes what the next step needs first

Two things in the guide have no skill range of their own:

- **Fel Iron Casing** for the Fel Iron Bombs at 322: it makes 3 first.
- **Volatile Blasting Trigger** for Box of Bombs at 406: the 12 from 370-376
  all go into the Explosive Decoys, so it makes 2 more crafts (2 each) first.

It counts your bags, so it skips this when you already have them. The label
says `first: Fel Iron Casing x3  for Fel Iron Bomb`.

### The key is an override

`SetOverrideBindingClick` while the button is shown, cleared when it is
hidden. Your own SHIFT-W comes straight back and nothing is written to your
keybind file. Binding is skipped in combat rather than attempted, because the
client blocks it there and throws the error at you.

The plan lives in `Plan.lua`, one entry per step of the guide with the recipe
name, the count and the reagents.

### It reads your skill, not your clicks

The current step is recomputed from `GetTradeSkillLine()` after every
tradeskill, bag or skill event. Counting presses instead would mean a lucky
run of skill-ups leaves you making something that has gone grey, and a dry run
moves you on too early. `tests/level.lua` walks all 449 levels and checks each
one points at the recipe the plan names.

The recipe's row is looked up **by name every time**, never remembered.
Collapsing a header or typing in the search box renumbers every row, and a
remembered index would then craft something else rather than fail.

Three states that are normal rather than errors, and say so instead of going
blank: the wrong profession window open, no reagents for the current step, and
not knowing the recipe at all. That last one can happen at 337, where White
Smoke Flare is a vendor schematic rather than a trainer one, so the button
names it and says so.

### What it does not do

Every craft is one of your clicks. Nothing in the addon presses anything: a
timer that clicked for you is what Warmane bans for, and it would also have to
guess when a craft finished, which it cannot. The button removes the looking
up, not the clicking.

## The two lists cannot drift apart

The shopping list and the craft plan are two hand-written descriptions of the
same guide, so `tests/plan.lua` checks that **every reagent any step needs is
either on the shopping list or made by an earlier step**.

That is not theoretical. The first guide's summary left out the Netherweave
Cloth its flare step consumed. The updated guide (18 Nov) is short in two
places: it lists 28 Mithril Bar where its own steps use 32, and 14 Fel Iron
Bar where the bolts take 14 and the bomb casings 9 more. The list carries 32
and 23, and the suite fails if any bought item drops below what the steps use.

## What prints to chat is alphabetical

`/mats` and `/mats show` print A to Z, because that list is read against the
auction house search box rather than against the levelling order.

The sort is done on a **copy**. `ns.lists` is the source of truth for `Plan.lua`
and for the Auctionator pusher, and reordering it in place to make one printout
nicer would quietly reorder those too.

## 1.2.0: Blacksmithing, Jewelcrafting and Enchanting (24 Nov 2026)

Routes from Lost Unison's "WotLK Warmane Icecrown Guides" docx, one file each:
`PlanBlacksmithing.lua`, `PlanJewelcrafting.lua`, `PlanEnchanting.lua`. Engineering
(`Plan.lua`, `Lists.lua`) is unchanged, still stopping at 405 by default.

**The panel** opens by itself on the right of the profession window and follows
whichever profession is open (the tabs pick one when no window is open). It shows:
- the big craft button (the same button as `/mats level`; SHIFT-W presses it)
- every mat for the rest of the route as have / need, bags plus the bank while it is open
- two columns, still needed **to the BiS level** and **to 450**
- **Push mats to 400 (BiS)** / **Push mats to 450**: only what you are short of for that level,
  into an Auctionator list (Engineering's route ends at its BiS 405, so it has one button)
- the BiS line: what the profession's own perk is and how far away, then "BiS reached",
  plus a raid-warning message and sound the moment you cross it
- drag the panel anywhere; next to the profession window the spot is remembered
Also `/mats`, and a **Mats** button on the auction house.

**Enchanting** puts each enchant on a grey, white or green item in your bags, never on
equipped gear, an epic, or an equipment-set item. "Other item" picks another one. When the
game asks "replace the enchant?" or "bind it?", the next press is the yes. Only those two
questions are ever answered.

**Jewelcrafting** "any Shadow Crystal / Forest Emerald gem" picks a known single-gem cut,
preferring one you have mats for, then orange over yellow over green. Icy Prism (20 h
cooldown) falls back to a meta gem when you carry an Earthsiege or Skyflare Diamond.

Guide totals corrected from its own steps: BS Fel Iron 54 (not 44), JC Mithril Filigree
9 crafts (not 8), Enchanting Infinite Dust 273 (not 246), Arcane Dust 90, Primal Might added.

BiS levels (`plan.bis`): Blacksmithing 400 (sockets, from the guide), Enchanting 400 (ring
enchants), Jewelcrafting 370 (Dragon's Eye), Engineering 405 (Nitro Boosts). The last three are
the game's requirements; the guide describes those perks without a level.

Test: `tests/professions.lua` (77 checks).
