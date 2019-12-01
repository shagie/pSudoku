package Sudoku::Util;

use strict;

# {
# 	my @p = getSubPair(1,2,3,4,5);
# 	foreach my $p (@p)
# 	{
# 		print "$p->[0], $p->[1]\n";
# 	}
# 	
# 	my @t = getSubTrip(1,2,3,4,5);
# 	foreach my $t (@t)
# 	{
# 		print "$t->[0], $t->[1], $t->[2]\n";
# 	}
# }
# 
# 
# exit;


sub getSubPair
{
	my (@n) = @_;
	my $tn;
	my @a;
	
	@n = sort @n;
	
	while(scalar @n)
	{
		$tn = shift @n;	
		foreach my $on (@n)
		{
			push @a, [$tn, $on];
		}
	}
	return @a;
}

sub getSubTrip
{
	my (@n) = @_;
	my %a;
	
	my @p = getSubPair(@n);
	@n = sort @n;
	
	while (scalar @p)
	{
		my $np = shift @p;
		
		foreach my $tn (@n)
		{
			next if($tn == $np->[0]);
			next if($tn == $np->[1]);
			
			$a{ join(',', sort(@$np, $tn )) } = [ sort(@$np, $tn ) ];
		}
	}
	return map { $a{$_} } sort keys %a;
}

1;
