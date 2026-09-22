#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition;

my $bath_volume_l = 20;
my @wafer_counts = (0, 100, 250, 600);

print "Copper-ion inventory for a ${bath_volume_l} L bath\n";
print "(300 mm wafers, 1 um Cu, 97% cathodic efficiency)\n\n";
printf "%-10s %-8s %12s %12s %12s\n",
    'anode', 'wafers', 'final [M]', 'change [%]', 'deficit [mol]';
print '-' x 62, "\n";

for my $anode_type (qw(soluble inert)) {
    my $model = Physics::Electrodeposition->new(
        anode_type       => $anode_type,
        current_density  => 20,
        target_thickness => 1,
        efficiency       => 0.97,
    );

    for my $wafer_count (@wafer_counts) {
        my $inventory = $model->bath_inventory(
            bath_volume_l => $bath_volume_l,
            wafer_count   => $wafer_count,
        );
        printf "%-10s %8d %12.4f %12.2f %12.4f%s\n",
            $anode_type,
            $wafer_count,
            $inventory->{final_ion_conc_M},
            $inventory->{concentration_change_percent},
            $inventory->{ion_deficit_mol},
            $inventory->{depleted} ? '  DEPLETED' : '';
    }
}
