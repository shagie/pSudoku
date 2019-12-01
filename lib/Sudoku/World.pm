package Sudoku::World;

use strict;
use lib "..";
use warnings;

use Hash::Util;
use Sudoku::Line;
use Sudoku::Value;

sub new
{
	my $class = shift;

	my $self = {};
	
	$self->{'world'} = [];
	$self->{'lines'} = [];
	$self->{'all'}   = [];
	$self->{'triplecounter'} = 1;
	
	bless $self,$class;
	
	Hash::Util::lock_keys(%$self);
	
	return $self;
}


###

sub printBoard
{
	my $self = shift;
	my $fh   = shift;
	
	my ($y, $x);
	
	$fh->print("<table style=\"border-collapse: collapse;\">\n");
	$fh->print("<tr><th>&nbsp;</th>\n");
	foreach my $i (1 .. 9)
	{
		$fh->print("<th style=\"border-bottom:3px solid black; border-collapse: collapse\">$i</th>");
	}
	$fh->print("<th>&nbsp;</th></tr>\n");
	
	foreach $y (0 .. 8)
	{
		$fh->print("<tr>\n");
		$fh->print("<th style=\"border-right:3px solid black; border-collapse: collapse\">". ($y+1) . "</th>");
		foreach $x (0 .. 8)
		{
			$self->{'world'}[$y][$x]->printCell($fh);
		}
		$fh->print("<th style=\"border-left:3px solid black; border-collapse: collapse\">". ($y+1) . "</th>");
		$fh->print("</tr>\n");
	}
	
	$fh->print("<tr><th>&nbsp;</th>\n");
	foreach my $i (1 .. 9)
	{
		$fh->print("<th style=\"border-top:3px solid black; border-collapse: collapse\">$i</th>");
	}
	$fh->print("<th>&nbsp;</th></tr>\n");
	$fh->print("</table>\n");	
}



sub fileInit
{
	my $self = shift;
	my $fh   = shift;
	my ($i, $x, $y);	
	my $slurp;
	
	while(<$fh>)
	{
		next if m/^#/;
		
		$slurp .= $_;
	}
	
	$slurp =~ s/\n//g;
	$slurp =~ s/ /0/g;
	$slurp =~ s/\./0/g;
	$slurp =~ s/[^0-9]//g;
	
	my @line = split(//,$slurp);
	
	$i= 0;
	foreach my $y (0 .. 8)
	{
		foreach my $x ( 0 .. 8)
		{
			my $here = new Sudoku::Value ( $x, $y, int($line[$i++]) ); 
			$self->{'world'}[$y][$x] = $here;
			push @{$self->{'all'}}, $here;
		}
	}
	$self->lineInit();
}

sub getBoardString
{
	my $self = shift;
	my $answer = "";
	foreach my $y (0 .. 8)
	{
		foreach my $x (0 .. 8)
		{
			$answer .= $self->{'world'}[$y][$x]->getValue();
		}
	}
	$answer;
}
	
	
sub lineInit
{
	my $self = shift;
	
	my $y;
	my $x;
	
	foreach $y (0 .. 8)
	{
		my $l = new Sudoku::Line("Y $y");;
		
		foreach $x (0 .. 8)
		{
			$l->append($self->{'world'}[$y][$x]);
		}
		
		push @{$self->{'lines'}} , $l;
	}
	
	foreach $x (0 .. 8)
	{
		my $l = new Sudoku::Line("X $x");;
		foreach $y (0 .. 8)
		{
			$l->append($self->{'world'}[$y][$x]);
		}
		push @{$self->{'lines'}} , $l;
	}

	my ($l1, $l2, $l3);
	
	$l1 = new Sudoku::Line("S 0");
	$l2 = new Sudoku::Line("S 1");
	$l3 = new Sudoku::Line("S 2");
	foreach $y (0 .. 2)
	{
		foreach $x (0 .. 2)
		{
			$l1->append($self->{'world'}[$y][$x]);
		}
		foreach $x (3 .. 5)
		{
			$l2->append($self->{'world'}[$y][$x]);
		}
		foreach $x (6 .. 8)
		{
			$l3->append($self->{'world'}[$y][$x]);
		}
	}
	push @{$self->{'lines'}} , $l1, $l2, $l3;

	$l1 = new Sudoku::Line("S 3");
	$l2 = new Sudoku::Line("S 4");
	$l3 = new Sudoku::Line("S 5");
	foreach $y (3 .. 5)
	{
		foreach $x (0 .. 2)
		{
			$l1->append($self->{'world'}[$y][$x]);
		}
		foreach $x (3 .. 5)
		{
			$l2->append($self->{'world'}[$y][$x]);
		}
		foreach $x (6 .. 8)
		{
			$l3->append($self->{'world'}[$y][$x]);
		}
	}
	push @{$self->{'lines'}} , $l1, $l2, $l3;
	
	$l1 = new Sudoku::Line("S 6");
	$l2 = new Sudoku::Line("S 7");
	$l3 = new Sudoku::Line("S 8");
	foreach $y (6 .. 8)
	{
		foreach $x (0 .. 2)
		{
			$l1->append($self->{'world'}[$y][$x]);
		}
		foreach $x (3 .. 5)
		{
			$l2->append($self->{'world'}[$y][$x]);
		}
		foreach $x (6 .. 8)
		{
			$l3->append($self->{'world'}[$y][$x]);
		}
	}
	push @{$self->{'lines'}} , $l1, $l2, $l3;
	
	# point zeros to the lines
	foreach my $z (@{$self->{'all'}})
	{
		$z->setLines( grep { $_->containsXY($z->getX(), $z->getY()) } @{$self->{'lines'}} );
	}
}

sub getZeros { my $s = shift; $s->getZero(); }

sub getZero
{
	my $self = shift;
	return grep { not $_->getValue() } @{$self->{'all'}};
}

sub getAll
{
	my $s = shift;
	return @{$s->{'all'}};
}

sub getLines
{
	my $self = shift;
	return @{$self->{'lines'}};
}

sub getLine
{
	my $self = shift;
	my $name = shift;
	
	return (grep { $_->getName() eq $name } @{$self->{'lines'}})[0];
}

sub resetColor
{
	my $self = shift;
	map { $_->resetColor() } @{$self->{'all'}};
}

sub getAtXY
{
	my $self = shift;
	my $x = shift;
	my $y = shift;
	return $self->{'world'}[$y][$x];
}

1;
