#!/usr/bin/perl -w

# This sort of implements shor's algorithm for factoring numbers, it should
# be possible to do it completely, which I might do later.

die 'usage: ./shor.pl [number to factor]' unless @ARGV;

use strict;
use warnings;
use Quantum::Entanglement qw(:complex);

my $num = $ARGV[0];

# do some early die'ing
die "$num is a multiple of two, here I am, brain the size..." unless $num %2;
die "$num is a non-integer, I only have whole numbers of fingers"
  unless $num == int($num);
die "$num is less than 15" unless $num >= 15;

print "Performing initial classical steps:\n";
# work out q value
my $q_power = int(2* log($num) / log(2)) +1;
my $q = 2 ** $q_power;

# pick some x so that x is coprime to n.
my $x;
do {
  $x = int(rand $num) + 1;
} until ($num % $x != 0 and $x > 2); #ok.. so this misses the point slightly

print "Using q:$q, x:$x\nStarting quantum steps\n";

# fill up a register with integers from 0..q-1
my $prob = 1/sqrt($q);
my $register1 = entangle(map {$prob, $_} (0..($q-1)));

# apply transformation F = x**|a> mod n, store in register 2
# (need to do a p_func to avoid overflow while **)

sub power_mod {
  my ($state, $x1, $num1) = @_;
  my $rt = 1;
  return 1 if $state == 0;
  return 1 if $state == 1;
  for (1..$state) {
    $rt = ($rt * $x1) % $num1;
  }
  return $rt;
}
print "Performing F = x**|a> mod n\n";
my $register2 = p_func(\&power_mod, $register1, $x, $num);

# We now observe $register2, thus partially collapsing reg1
my $k = "$register2";

print "\$register2 collapsed to $k\n";
print "Finding period of F\n";
# technically, we should compute a FFT on the states of reg1 here, but I'm
# not doing that, instead I'll find the period by cheating, it should be
# possible to do this properly, but I've not got the time right now, and
# it would require writing a general FFT within Q::E

my $period = 0; my $last = 0;
sub cheat {
  my $state = $_[0];
  $period = $state - $last if $state;
  $last = $state if $state;
  return $period;
}
p_func(\&cheat, $register1);

print "Period of F = x**|a> mod n is $period\n";

# now given the period, we need to work out the factor of n
# work out the two thingies:

if ($period % 2 != 0) {
  print "$period is not an even number, doubling to";
  $period *=2;
  print " $period\n";
}

my $one = $x**($period/2) -1;
my $two = $x**($period/2) +1;

# one and two must have a gcd in common with n, which we now find...
print "$one * $two and $num might share a gcd (classical step)\n";
my ($max1, $max2) = (1,1);
for (2..$num) {
  last if $_ > $num;
  unless (($num % $_) || ($one % $_)) {
    $max1 = $_;
  }
  unless (($num % $_) || ($two % $_)) {
    $max2 = $_;
  }
}
print "$max1, $max2 could be factors of $num\n";
