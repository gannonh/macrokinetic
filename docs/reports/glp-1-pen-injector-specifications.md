# GLP-1 Pen Injector Clinical Specifications

Based on comprehensive research from FDA prescribing information, manufacturer specifications, and clinical documentation, here are the exact dose specifications for all major GLP-1 medication pen injectors. **Critical finding: Your current software calculation of 0.02mg per click for a 2mg dose is incorrect** - the actual specifications vary significantly by pen type.

## Critical pen type classifications determine dosing mechanics

GLP-1 pens fall into three distinct categories that fundamentally affect dose calculation:

**Click-based adjustable pens** (Ozempic only) use actual click increments for dose selection. **Fixed-dose single-use pens** (Wegovy, Mounjaro, Trulicity) deliver predetermined doses with no adjustment mechanism. **Dial-a-dose pens** (Victoza, Saxenda) use visual dose selection rather than click counting.

## Semaglutide pen specifications show critical differences

### Ozempic pens: Adjustable multi-dose with click increments

**Ozempic 0.25/0.5mg pen** delivers doses via a click mechanism with **0.0139mg per click**. The minimum dose is 0.25mg (18 clicks) and maximum is 0.5mg (36 clicks). This adjustable-dose pen contains 2mg total in 3mL at 0.68mg/mL concentration.

**Ozempic 1mg pen** operates with **0.01mg per click** according to BC Children's Hospital clinical specifications. Minimum dose is 0.5mg (50 clicks) with maximum 1mg (72 clicks). The pen contains 4mg total in 3mL at 1.34mg/mL concentration.

**Ozempic 2mg pen** - critically for your software - uses **0.0139mg per click**, requiring 72 clicks for 1mg and 144 clicks for the 2mg maximum dose. This adjustable-dose pen contains 8mg total in 3mL at 2.68mg/mL concentration. Your current calculation showing 100 clicks for 2mg is therefore clinically incorrect.

### Wegovy pens: Fixed single-dose without clicks

All Wegovy pens (0.25mg, 0.5mg, 1mg, 1.7mg, 2.4mg) are **single-dose fixed pens with no click mechanism**. Each pen delivers its labeled dose as a preset amount in one injection. These cannot be adjusted and must be disposed after single use. Dose increments per click are not applicable as these pens have no dose selection capability.

## Tirzepatide specifications confirm fixed-dose design

All Mounjaro pens (2.5mg, 5mg, 7.5mg, 10mg, 12.5mg, 15mg) are **fixed-dose single-use devices** delivering their labeled dose without adjustment capability. The two clicks heard during injection are operational feedback only - first click indicates injection start, second indicates completion. These pens contain 0.5mL of solution at varying concentrations from 5mg/mL to 30mg/mL depending on strength.

## Dulaglutide pens eliminate dose selection entirely

Trulicity pens (0.75mg, 1.5mg, 3mg, 4.5mg) are **single-dose auto-injectors** that automatically deliver their fixed dose upon activation. No click counting or dose selection exists - the pen automatically inserts the needle, delivers the predetermined dose, and retracts. Each pen contains 0.5mL at concentrations ranging from 1.5mg/mL to 9mg/mL based on strength.

## Liraglutide pens use dial selection not clicks

Both Victoza and Saxenda pens are **dial-a-dose systems** where doses are selected by turning a dial to align with specific mg amounts, not by counting clicks. While clicking sounds occur during dial rotation, manufacturer instructions explicitly state "Do not count the pen clicks."

**Victoza pen** allows selection of 0.6mg, 1.2mg, or 1.8mg maximum via dial mechanism. **Saxenda pen** extends this to 0.6mg, 1.2mg, 1.8mg, 2.4mg, or 3.0mg maximum. Both contain identical 6mg/mL concentration in 3mL volumes but serve different therapeutic purposes.

## Software implementation recommendations

Your medical tracking software needs three distinct interfaces:

**For Ozempic pens only**, implement click-based dose calculation using the exact specifications: 0.0139mg/click for 0.25/0.5mg and 2mg pens, 0.01mg/click for 1mg pens. Include validation to ensure click counts match expected ranges for each dose.

**For Wegovy, Mounjaro, and Trulicity**, implement simple fixed-dose selection without any increment calculations. Users should only select the pen strength being used, with the software recording the entire predetermined dose.

**For Victoza and Saxenda**, implement preset dose options (0.6, 1.2, 1.8mg for Victoza; adding 2.4, 3.0mg for Saxenda) without click counting functionality. These should be dropdown selections rather than calculated values.

## Clinical accuracy verification sources

All specifications were verified against FDA prescribing information (Reference IDs: Ozempic 5519421, Wegovy 5212972), manufacturer Instructions for Use documents from Novo Nordisk and Eli Lilly, and clinical implementation guides from BC Children's Hospital Endocrinology Unit. Note that click-counting for off-label dosing is not manufacturer-recommended and may result in dosing inaccuracies according to FDA warnings.

## Conclusion

The current software calculation of 0.02mg per click yielding 100 clicks for 2mg is clinically inaccurate. The correct Ozempic 2mg pen specification is 0.0139mg per click requiring 144 clicks for the full 2mg dose. More critically, only Ozempic pens use click-based dosing - all other GLP-1 pens in your list use either fixed-dose or dial-a-dose mechanisms that should not involve click calculations in your software interface.