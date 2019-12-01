package Sudoku::Value;

use strict;
use lib "..";
use warnings;

use Hash::Util;
use Sudoku::Line;

sub new
{
	my $class = shift;
	my $x = shift;
	my $y = shift;
	my $v = shift;

	my $self = {};
	
	$self->{'impossible'} = {};
	$self->{'x'} = $x;
	$self->{'y'} = $y;
	$self->{'value'} = $v;
	$self->{'lines'} = [];
	$self->{'color'} = {'value' => 'black',
						 '1'    => 'grey',
						 '2'    => 'grey',
						 '3'    => 'grey',
						 '4'    => 'grey',
						 '5'    => 'grey',
						 '6'    => 'grey',
						 '7'    => 'grey',
						 '8'    => 'grey',
						 '9'    => 'grey',
						};
	
	$self->{'chain'} = 0;
	
	bless $self,$class;
	
	Hash::Util::lock_keys(%$self);
	
	return $self;
}


###

sub printCell
{
	my $self = shift;
	my $fh   = shift;
	
	my $bl = ($self->{'x'} %3)?1:2;
	my $bb = ($self->{'y'} %3)?1:2;
	
	my $style = "border-left:${bl}px solid black; border-top:${bb}px solid black; border-collapse:collapse";
	
	if( $self->{'value'} )
	{
		$fh->print(<< "--EOB");
<td align="center" valign="center" style="$style"><table>
<tr><td width='10'>&nbsp;</td><td width='10'>&nbsp;</td><td width='10'>&nbsp;</td></tr>
<tr><td>&nbsp;</td><td><font color="$self->{'color'}{'value'}">$self->{'value'}</font></td><td>&nbsp;</td></tr>
<tr><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>
</table></td>
--EOB
	}
	else
	{
		$fh->print("<td align=\"center\" valign=\"center\" style=\"$style\"><table ><tr>");
		foreach my $i ( 1 .. 9 )
		{
			if(defined $self->{'impossible'}{$i})
			{
				if($self->{'color'}{$i} eq 'grey')
				{
					$fh->print("<td width='10'>.</td>");
				}
				else
				{
					$fh->print("<td width='10' bgcolor=\"$self->{'color'}{$i}\" >&nbsp;</td>");
				}
			}
			else
			{
				$fh->print("<td width='10'><font color=\"$self->{'color'}{$i}\">$i</font></td>");
			}
			if(not $i % 3) { $fh->print ("</tr><tr>") };
		}
		$fh->print("</tr></table></td>");
	}
	$fh->print("\n");
}

sub printReason
{
	my $s  = shift;
	my $fh = shift;
	
	$fh->print("$s->{'x'}, $s->{'y'} -- $s->{'value'}\n");
	
	foreach my $i (keys %{$s->{'impossible'}})
	{
		$fh->print("$s->{'x'}, $s->{'y'} $i step $s->{'impossible'}{$i}{'step'} : $s->{'impossible'}{$i}{'reason'}\n");
	}
}

sub print
{
	my $self = shift;
	print "$self->{'x'}, $self->{'y'}, $self->{'value'}";
	if($self->{'value'})
	{
	}
	else
	{
		print " ";
		print join(',',$self->getPossible());
	}
	print "\n";
}

sub setValue
{
	my $self  = shift;
	my $value = shift;
	
	$self->{'value'}  = $value;
}

sub setImpossible
{
	my $self = shift;
	my $v    = shift;
	my $r    = shift;
	my $i    = shift;
	
	$self->{'impossible'}{$v}{'step'}   = $i;
	$self->{'impossible'}{$v}{'reason'} = $r;
}

sub setColor
{
	my $self = shift;
	my $c    = shift;
	my $v    = shift;
	
	if(not defined $v) { $v = 'value'; }
	$self->{'color'}{$v} = $c;
}

sub resetColor
{
	my $self = shift;
	$self->{'color'}{'value'} = 'black';
	foreach my $i ( 1 .. 9 )
	{
		$self->{'color'}{$i} = 'grey';
	}
}

sub getPossible
{
	my $self = shift;
	return grep { not defined $self->{'impossible'}{$_} } (1 .. 9)
}

sub getImpossible
{
	my $self = shift;
	return map { [ $_, $self->{'impossible'}{$_}{'step'}, $self->{'impossible'}{$_}{'reason'} ] } keys %{$self->{'impossible'}};
}

sub isPossible
{
	my $self = shift;
	my $v    = shift;
	
	if($self->getValue()) { return 0; }
	
	return not defined $self->{'impossible'}{$v};
}

sub getValue
{
	my $self = shift;
	$self->{'value'};
}

sub getX
{
	my $self = shift;
	$self->{'x'};
}

sub getY
{
	my $self = shift;
	$self->{'y'};
}

sub getXY
{
	my $s = shift;
	$s->{'x'} . "," . $s->{'y'};
}

sub getRC
{
	my $s = shift;
	"r".($s->{'y'} +1) . "c" . ($s->{'x'} +1);
}

sub setLines
{
	my $self = shift;
	$self->{'lines'} = [ @_ ];
}

sub getLines
{
	my $self = shift;
	@{$self->{'lines'}};
}

sub commonTo
{
	my $self = shift;
	my @lines = @_;
		
	foreach my $line (@lines)
	{
		if(not $line->contains($self))
		{
			return 0;
		}
	}
	
	1;
}

sub setChain
{
	my $s = shift;
	$s->{'chain'} = shift;
}

sub getChain
{
	my $s = shift;
	$s->{'chain'};
}

sub equals
{
	my $self  = shift;
	my $other = shift;
	return ($self->getX == $other->getX and $self->getY == $other->getY);
}

1;
