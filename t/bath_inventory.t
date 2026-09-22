#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

use Physics::Electrodeposition;

sub near {
    my ($actual, $expected, $tolerance, $label) = @_;
    cmp_ok(abs($actual - $expected), '<=', $tolerance, $label);
}

my $inert = Physics::Electrodeposition->new(
    anode_type => 'inert', target_thickness => 1, efficiency => 0.97,
);
my $per_wafer = $inert->mass_balance;
my $inventory = $inert->bath_inventory(bath_volume_l => 10, wafer_count => 5);

near($inventory->{initial_ion_mol}, 2.8, 1e-12,
     'initial inventory is molarity times bath volume');
near($inventory->{ion_consumed_mol}, 5 * $per_wafer->{ion_consumed_mol}, 1e-12,
     'per-wafer consumption scales with wafer count');
is($inventory->{ion_replenished_mol}, 0,
   'inert anode does not replenish metal ion');
near(
    $inventory->{final_ion_mol},
    $inventory->{initial_ion_mol} - $inventory->{ion_consumed_mol},
    1e-12,
    'inert-anode final inventory closes the ion balance',
);
near($inventory->{final_ion_conc_M}, $inventory->{final_ion_mol} / 10, 1e-12,
     'final molarity accounts for bath volume');
cmp_ok($inventory->{concentration_change_percent}, '<', 0,
       'inert anode depletes bath concentration');
ok(!$inventory->{depleted}, 'adequately sized bath is not depleted');

my $soluble = Physics::Electrodeposition->new(
    anode_type => 'soluble', target_thickness => 1, efficiency => 0.97,
);
my $soluble_inventory = $soluble->bath_inventory(
    bath_volume_l => 10, wafer_count => 5,
);
cmp_ok($soluble_inventory->{ion_replenished_mol}, '>',
       $soluble_inventory->{ion_consumed_mol},
       'soluble anode replenishes total charge while cathode efficiency is below one');
cmp_ok($soluble_inventory->{final_ion_conc_M}, '>', 0.28,
       'soluble anode predicts the corresponding small concentration increase');

my $initial = $inert->bath_inventory(bath_volume_l => 10, wafer_count => 0);
is($initial->{final_ion_conc_M}, 0.28,
   'zero wafers returns the unchanged initial bath');

my $depleted = $inert->bath_inventory(bath_volume_l => 0.001, wafer_count => 1);
ok($depleted->{depleted}, 'undersized bath is flagged as depleted');
is($depleted->{final_ion_mol}, 0, 'physical final inventory is clamped at zero');
cmp_ok($depleted->{ion_deficit_mol}, '>', 0, 'unmet ion demand is reported');

for my $case (
    [sub { $inert->bath_inventory() }, qr/bath_volume_l is required/,
        'bath volume is required'],
    [sub { $inert->bath_inventory(bath_volume_l => 0) }, qr/positive number/,
        'zero bath volume is rejected'],
    [sub { $inert->bath_inventory(bath_volume_l => 'large') }, qr/positive number/,
        'non-numeric bath volume is rejected'],
    [sub { $inert->bath_inventory(bath_volume_l => 'Inf') }, qr/positive number/,
        'infinite bath volume is rejected'],
    [sub { $inert->bath_inventory(bath_volume_l => 10, wafer_count => -1) },
        qr/non-negative integer/, 'negative wafer count is rejected'],
    [sub { $inert->bath_inventory(bath_volume_l => 10, wafer_count => 1.5) },
        qr/non-negative integer/, 'fractional wafer count is rejected'],
    [sub { $inert->bath_inventory(bath_volume_l => 10, wafer_count => 'Inf') },
        qr/non-negative integer/, 'infinite wafer count is rejected'],
) {
    my ($code, $pattern, $label) = @$case;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like($error, $pattern, $label);
}

done_testing();
