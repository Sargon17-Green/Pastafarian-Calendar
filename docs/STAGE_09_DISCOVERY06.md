# Stage 9 / DISCOVERY06 — సాస్ కుండల స్వతంత్ర పునర్నిర్మాణం

## Input and bounded scope
Stage8 was accepted at SHA b66af81b1e753ef18bed1e542d983338b937c5cc, Actions 41187141754: all 9/9 jobs completed/success; GNAT13 compile/bind/link and 438 assertions. Stage9 independently reconstructs the mixing portion of Sauce: initial six bowls, 46 visible-drop mixing rounds, factorial unranking of bowl order and 12 final stirs. Reference values are not computed by Sauce or its internal mixing/stir/order functions.

For boundedness, Stage9 uses production Compute_Work_Counts, Build_Stones, Build_Hidden_Drops and Build_Visible_Drops as upstream inputs. Therefore this is NOT an independent oracle for drop-generation algebra or full Calendar_Date. No production or five-field changes.

## Contract
Inputs: eight literal date pairs, covering same day, adjacent days, reverse direction, Tablets day, +/-400 and two distant cases. For each pair, compare six bowl residues, six order positions and check order uniqueness: 13 assertions per case. Add two literal factoradic endpoint assertions (order 1 and 720): 8 x 13 + 2 = 106 assertions. Exact marker STAGE09_DISCOVERY06_ASSERTIONS= 106. Test-only reference uses modular projection and its own unranking, and does not call Save, Square or public order generation.

## Acceptance
Ubuntu 24.04, GNAT 13, sh ./run_stage09_discovery06.sh, 15-minute timeout. Require verify and native-stage09-discovery06 completed/success on same HEAD, compile/bind/link, exact 106 marker. Queued/in_progress is not PASS or blocker. For failure, capture input pair, actual/expected, compiler/runtime log before declaring a defect. No main/merge/publish; approved CI provides Native so no local user-run package.
