package Sudoku::Line;

use strict;
use warnings;


sub new
{
	my $class = shift;
	my $name  = shift;
	my $self  = {};
	
	$self->{'array'} = [];
	$self->{'name'}  = $name;
	
	bless $self, $class;
}

sub append
{
	my $self = shift;
	push @{$self->{'array'}}, @_;
}

sub contains
{
	my $self = shift;
	my $v    = shift;
	return $self->containsXY($v->getX,$v->getY);
}

sub containsXY
{
	my $self = shift;
	my ($x, $y) = @_;
	return scalar grep { $_->getX() == $x and $_->getY() == $y } @{$self->{'array'}};
}

sub containsV
{
	my $self = shift;
	my $v    = shift;
	
	my @a = grep { $_->getValue() == $v } @{$self->{'array'}};
	if(scalar @a)
	{
		return $a[0];
	}
	else
	{
		return undef;
	}	
}

sub getName
{
	my $self = shift;
	$self->{'name'};
}

sub getPrintName
{
	my $self = shift;
	my $name = shift;
	if (not defined $name) { $name = $self->{'name'}; }
	my ($n, $p) = split(/ /,$name);
	$p += 1;
	$n =~ s/Y/r/;
	$n =~ s/X/c/;
	$n =~ s/S/s/;
	
	"$n$p";
}

sub possibleValue
{
	my $self = shift;
	my $value = shift;
	my @answer = ();
	
    foreach my $z ( grep { not $_->getValue() } @{$self->{'array'}} )
    {
    	if( scalar(grep { $_ == $value } $z->getPossible) )
    	{
    		push @answer,$z
    	}
    }
	@answer;
}

sub getZeros
{
	my $self = shift;
	grep { not $_->getValue() } @{$self->{'array'}};
}

1;
