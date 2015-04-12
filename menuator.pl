#!/usr/bin/perl
#
# Copyright (c) 2015, Ethan Dicks and the Epicurious 2015 Space Apps Challenge Team
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.


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
use Text::ASCIITable;

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
	foreach my $component (@{$ingredients{$entree}}) {
		$compartments{$component}++;  # mark this one down (and do crude use-count stats)
	}
}

my $ccount = scalar(keys %compartments);
print join("\n", %compartments) if ($verbose > 4);
print "There are $maxbins spaces available, and $ccount bins requested.\n";
if ($ccount > $maxbins) {
	print "Too many individual ingredients required for this frame.  Cannot create load map.\n";
	exit;
}

# assume 2 trays of 3x3 for now ToDo: dynamic sizing
my %c = %compartments; #cheap hack to save typing

my @bins = ();
foreach my $item (keys %compartments) {
	push (@bins, $item);
}

for (my $i = 0; $i < ($maxbins - $ccount); $i++) {
	push (@bins, "Empty"); 
}

print join("\n", @bins), "\n";

my $cwid = 23;
my $t1 = Text::ASCIITable->new({ headingText => 'Left Tray' });
$t1->setCols('one','two','three');
$t1->setColWidth('one',$cwid,1);
$t1->setColWidth('two',$cwid,1);
$t1->setColWidth('three',$cwid,1);
$t1->setOptions({ hide_HeadRow => 1 });
$t1->addRow($bins[0], $bins[1], $bins[2]);
$t1->addRowLine();
$t1->addRow(@bins[3..5]);
$t1->addRowLine();
$t1->addRow(@bins[6..8]);
$t1->addRowLine();

my $t2 = Text::ASCIITable->new({ headingText => 'Right Tray' });
$t2->setCols('one','two','three');
$t2->setColWidth('one',$cwid,1);
$t2->setColWidth('two',$cwid,1);
$t2->setColWidth('three',$cwid,1);
$t2->setOptions({ hide_HeadRow => 1 });
$t2->addRow(@bins[9..11]);
$t2->addRowLine();
$t2->addRow(@bins[12..14]);
$t2->addRowLine();
$t2->addRow(@bins[15..17]);
$t2->addRowLine();


print $t1, "\n", $t2;

exit;
