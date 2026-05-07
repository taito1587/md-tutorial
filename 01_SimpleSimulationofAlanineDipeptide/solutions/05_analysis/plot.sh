#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Generate plots for the heating + production runs.
#
# This script does two things:
#   (1) runs `process_mdout.perl` to produce per-property summary files
#       (summary.TEMP, summary.DENSITY, summary.ETOT, ...).
#   (2) prints the gnuplot commands you can run interactively.
#
# Run from workspace/05_analysis/ after the production MD has finished.
# -----------------------------------------------------------------------------

set -euo pipefail

# process_mdout.perl ships with AmberTools and reads sander/pmemd .out files,
# splitting them into one summary.* file per property (temperature, density,
# total energy, etc.) for easy plotting.
process_mdout.perl ../03_heating/02_Heat.out ../04_production/03_Prod.out

echo ""
echo "Generated summary files:"
ls summary.* 2>/dev/null | sed 's/^/  /'

echo ""
echo "Suggested plots (run any of these in the dev shell):"
echo ""
echo "  # Open an interactive gnuplot window (close with Ctrl-D or 'exit')"
echo "  gnuplot -p -e 'set title \"Temperature\"; set xlabel \"step\"; set ylabel \"T [K]\"; plot \"summary.TEMP\" with lines'"
echo ""
echo "  gnuplot -p -e 'set title \"Density\";     set xlabel \"step\"; set ylabel \"rho [g/cc]\"; plot \"summary.DENSITY\" with lines'"
echo ""
echo "  gnuplot -p -e 'set title \"RMSD (ALA)\";  set xlabel \"time [ps]\"; set ylabel \"RMSD [A]\"; plot \"02_03.rms\" with lines'"
echo ""
echo "  # Save as PNG instead of opening a window:"
echo "  gnuplot -e 'set terminal png size 800,600; set output \"temp.png\"; plot \"summary.TEMP\" with lines'"
