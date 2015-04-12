#!/usr/bin/perl

use strict;
use warnings;

# debug flags
my $verbose = 3;

# limits on machine capacity
my $bins_per_side = 9;
my $sides = 2;
my $maxbins = $bins_per_side * $sides;

# accmulation spots
my %feedstock_tally;
my %ingredients;
my %compartments;

use Text::CSV;
my $csv = Text::CSV->new({ sep_char => ',' });

my $file = $ARGV[0] or die "Usage: $0 <CSV file> <entree> <entree> <entree>\n";

my $sum = 0;

open(my $data, '<', $file) or die "Could not open '$file' $!\n";

# grab the header row
my $line = <$data>;

$csv->parse($line); # or die "Couldn't parse header row\n";

my @feedstock = $csv->fields();

for (my $i = 0; $i < scalar(@feedstock); $i++) {
#       splice @feedstock, $i, 1 unless defined $feedstock[$i] and $feedstock[$i];
        # edit/clean up feedstock names
        $feedstock[$i] =~ s![Ss]ource!!o;
        $feedstock[$i] =~ s!\(.*\)!!o;
        $feedstock[$i] =~ s!\?!!o;
        $feedstock[$i] =~ s!\s*$!!o;

        # start a count of what we need to make every meal (and remember things we don't use at all)
        $feedstock_tally{$feedstock[$i]} = 0 if defined $feedstock[$i] and $feedstock[$i];
}

#print join("\n", @feedstock);

#print join("\n", %feedstock_tally);

#exit;

# read in the rest of the file
while (my $line = <$data>) {
        chomp $line;
        $line =~ s!http.*$!!o;  # remove URLs from entree item

        unless ($csv->parse($line)) {
                warn "Entree Line could not be parsed: $line\n";
        } else {
                my @entree = $csv->fields();
                next unless defined($entree[0]) and $entree[0];

                print "What's in $entree[0]?\n" if $verbose > 2;
                @{$ingredients{$entree[0]}} = ();  # make a place to put ingredients
                for (my $i = 1; $i < scalar(@entree); $i++) {
                        if ($entree[$i]) {
                                $feedstock_tally{$feedstock[$i]}++;  # remember we used this
                                print "  $feedstock[$i]\n" if ($verbose > 2);
                                push(@{$ingredients{$entree[0]}}, $feedstock[$i]); # remember we need this
                        }

                }

        }
}
print join("\n", %feedstock_tally) if ($verbose > 4);

# display list of how many entrees use each feedstock ingredient
my @unused_feedstock;

foreach my $item (sort { $feedstock_tally{$b} <=> $feedstock_tally{$a} or $a cmp $b } keys %feedstock_tally) {
        if ($feedstock_tally{$item} > 0) {
                print "$item is used in $feedstock_tally{$item} recipes\n";
        } else {
                print "$item is not required for any recipes\n";
        }
}

if (scalar(@ARGV) == 1) {
        print "No recipes requested.  No loadout produced.\n";
        exit;
}

foreach my $entree (@ARGV) {
        next if $entree =~ m!.csv$!;  # skip the filename
        print "Trying to match $entree\n";
        unless (scalar(@{$ingredients{$entree}})) {
                print "Don't know how to make that\n";
                next;
        }
        print "It's made from ", join(",", @{$ingredients{$entree}}), "\n";
}

exit;
