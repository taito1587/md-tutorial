#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Generate energy/temperature/density summary files from .out logs.
# Run from workspace/05_analysis/ after all MD has finished.
# -----------------------------------------------------------------------------

set -euo pipefail

mkdir -p summary_explicit summary_vac summary_gb

# Explicit-solvent run (most informative; has heating + production)
(cd summary_explicit && process_mdout.perl \
    ../../04_explicit_solvent/heat.out \
    ../../04_explicit_solvent/prod.out)

# GB run
(cd summary_gb && process_mdout.perl ../../03_implicit_solvent/md.out)

# Vacuum runs
(cd summary_vac && process_mdout.perl \
    ../../02_vacuum_md/md_12Acut.out \
    ../../02_vacuum_md/md_nocut.out)

echo ""
echo "Summary files generated:"
ls -1 summary_*/

echo ""
echo "Suggested plots (run in dev shell):"
echo ""
echo "  # Compare DNA backbone RMSD across all 3 solvent models:"
echo "  gnuplot -p -e 'plot \"vac_12Acut.rms\" w l t \"vacuum 12A cut\", \\"
echo "                      \"vac_nocut.rms\"  w l t \"vacuum no cut\", \\"
echo "                      \"gb.rms\"         w l t \"GB implicit\", \\"
echo "                      \"explicit.rms\"   w l t \"TIP3P explicit\"'"
echo ""
echo "  # Temperature trace of explicit run:"
echo "  gnuplot -p -e 'plot \"summary_explicit/summary.TEMP\" w l'"
echo ""
echo "  # Density of explicit run (should settle near 1.0 g/cc):"
echo "  gnuplot -p -e 'plot \"summary_explicit/summary.DENSITY\" w l'"
