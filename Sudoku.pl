#!/usr/local/bin/perl

use strict;
use lib "./lib";
use warnings;

use FileHandle;

use Sudoku::World;
use Sudoku::Util;

# config variables
my $forbiden_rectangle = 0;


{
	my $world = new Sudoku::World;
	
	my $OUTfh = new FileHandle "> ./out.html";
	my $INfh  = new FileHandle;
	
	$INfh->open("./Boards/file.txt");
	$world->fileInit($INfh);
	$INfh->close;
	
	$OUTfh->print("<html><head><title>Sudoku</title></head><body>\n");
	$OUTfh->print("<h1>Original board</h1>\n");
	$OUTfh->print("<tt>" . $world->getBoardString() . "</tt>\n");
	$world->printBoard($OUTfh);
	
	
	my $done   = 0;
	my $change = 0;
	my $i      = 0;
	my %used   = ();
	
	REDUCE:
	while(not $done)
	{
		$i++;
		$world->resetColor();
		
		$OUTfh->print("<hr /><h1>$i</h1>\n");
		
		# reduceSimple *MUST* be first
		if(reduceSimple($world,$i,$OUTfh))
		{
			$OUTfh->print("Simple Reduce");
			$world->printBoard($OUTfh);
			$used{'simple'}++;
			redo REDUCE;
		}
		
		if(reduceForced($world,$i,$OUTfh))
		{
			$OUTfh->print("Forces");
			$world->printBoard($OUTfh);
			$used{'forced'}++;
			redo REDUCE;
		}
		
		if(reduceOnly($world,$i,$OUTfh))
		{
			#$OUTfh->print("Only");	# printed in reduce
			$world->printBoard($OUTfh);
			$used{'only'}++;
			redo REDUCE;
		}
		
		if($forbiden_rectangle and reduceForbidenRectangle($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'forbiden rectangle'}++;
			redo REDUCE;
		}
		
		if(reduceNakedPair($world,$i,$OUTfh))
		{
			$OUTfh->print("Naked Pair");
			$world->printBoard($OUTfh);
			$used{'naked pair'}++;
			redo REDUCE;
		}
		
		if(reduceHiddenPair($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'hidden pair'}++;
			redo REDUCE;
		}
		
		if(reduceHiddenTriple($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'hidden triple'}++;
			redo REDUCE;
		}
		
		if(reduceXWing($world,$i,$OUTfh))
		{
			#$OUTfh->print("Intersect");	# printed in reduce
			$world->printBoard($OUTfh);
			$used{'xwing'}++;
			redo REDUCE;
		}
		
		if(reduceIntersect($world,$i,$OUTfh))
		{
			#$OUTfh->print("Intersect");	# printed in reduce
			$world->printBoard($OUTfh);
			$used{'intersect'}++;
			redo REDUCE;
		}
		
		if(reduceBlockBlock($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'block block'}++;
			redo REDUCE;
		}

		if(reduceYWing($world,$i,$OUTfh))
		{
			#$OUTfh->print("YWing");	# printed in reduce
			$world->printBoard($OUTfh);
			$used{'ywing'}++;
			redo REDUCE;
		}

		if(reduceAPE($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'ape'}++;
			redo REDUCE;
		}
		
		
		if(reduceChain($world,$i,$OUTfh))
		{
			$world->printBoard($OUTfh);
			$used{'chain'}++;
			redo REDUCE;
		}
		
		$done = 1;
	}
	
	$OUTfh->print("<h1>Final board</h1>\n");
	$world->printBoard($OUTfh);
	$OUTfh->print("<table>\n");
	foreach my $key ( sort { $used{$b} <=> $used{$a} } keys %used)
	{
		$OUTfh->print("<tr><td>$key</td><td align=\"right\">$used{$key}</td></tr>\n");
	}
	$OUTfh->print("</table>\n");	
	$OUTfh->print("<tt>" . $world->getBoardString() . "</tt>\n");
	$OUTfh->print("</body></html>\n");
	$OUTfh->close();
}

exit;

sub reduceBlockBlock
{
	my ($w, $i, $fh) = @_;
	
	my @blocks = (
		{'S' => [1,2,3],
		 'X' => [1,2,3]
		},
		
		{'S' => [ 4,5,6],
		 'X' => [ 4,5,6],
		},
		
		{'S' => [ 7,8,9],
		 'X' => [ 7,8,9],
		},
		
		{'S' => [1,4,7],
		 'Y' => [1,2,3],
		},
		
		{'S' => [2,5,8],
		 'Y' => [4,5,6],
		},
		
		{'S' => [3,6,9],
		 'Y' => [7,8,9]
		}
	);
	0;
}


# this function works on the asumption that there is only one solution to the
# Sudoku problem.
sub reduceForbidenRectangle
{
	my ($w, $i, $fh) = @_;
	
	my %zh = ();
	foreach my $z ($w->getZeros())
	{
		next unless scalar($z->getPossible()) == 2;
		push @{$zh{join(',',sort $z->getPossible)}}, $z;
	}
	
	foreach my $zhkey (grep { scalar(@{$zh{$_}}) == 3} keys %zh)
	{
		# do these three form a rectangle?
		# TODO: extend to same block 'rectangle'
		
		my %x; my %y;
		my $zset = $zh{$zhkey};
		foreach my $zi (@{$zset})
		{
			$x{$zi->getX()}++;
			$y{$zi->getY()}++;
		}
		my @xs = sort values %x;
		my @ys = sort values %y;
		if($xs[0] == 1 and $xs[1] == 2 and
		   $ys[0] == 1 and $ys[1] == 2)
		{
			my $answer = 0;
			my $x = (grep { $x{$_} == 1 } keys %x)[0];
			my $y = (grep { $y{$_} == 1 } keys %y)[0];
			
			my $c = $w->getAtXY($x,$y);
			next if($c->getValue());	# already assigned a value there.
			
			if($c->isPossible(($zset->[0]->getPossible())[0]))
			{
				$c->setImpossible(($zset->[0]->getPossible())[0],"forbiden rect",$i);
				$c->setColor('red',($zset->[0]->getPossible())[0]);
				$answer = 1;
			}
			if($c->isPossible(($zset->[0]->getPossible())[1]))
			{
				$c->setImpossible(($zset->[0]->getPossible())[1],"forbiden rect",$i);
				$c->setColor('red',($zset->[0]->getPossible())[1]);
				$answer = 1;
			}
			
			if($answer)
			{
				$fh->print("Forbiden rectangle eliminates ". join(', ', $zset->[0]->getPossible) . " from " . $c->getRC() . "<br />");
				foreach my $zi (@$zset)
				{
					foreach my $p ($zi->getPossible())
					{
						$zi->setColor('blue',$p);
					}
				}
				return 1;
			}
		}
	}
	
	0;
}

sub reduceAPE
{
	my ($w, $i, $fh) = @_;
	
	my @aps; # allied pairs
	
	my @zs = $w->getZeros();
	foreach my $z1 (@zs)
	{
		foreach my $z2 (@zs)
		{
			next if ($z1->equals($z2));
			next unless ((grep { $_->getName() =~ m/S/ } $z1->getLines())[0] eq 
			             (grep { $_->getName() =~ m/S/ } $z2->getLines())[0]);
			next unless ($z1->getX() == $z2->getX() or
			             $z1->getY() == $z2->getY());
			
			push @aps, [$z1,$z2];
			
		}
	}
	
	foreach my $ap (@aps)
	{
		my @l = grep { $_->contains($ap->[0]) and $_->contains($ap->[1]) } $w->getLines();
		
		my %apv = ();
		my %opav = ();	# used for coloring and trace
		
		foreach my $p0 ($ap->[0]->getPossible())
		{
			foreach my $p1 ($ap->[1]->getPossible())
			{
				next if($p0 == $p1);
				$apv{join(',',$p0,$p1)} = 1;
				$opav{join(',',$p0,$p1)} = ['&nbsp;'];
			}
		}
		
		# apv contains the value pairs for the allied pair
		
		my @c;
		my @t;
		my $lc = 0;

		foreach my $lk (@l)
		{
			my %trip;
			@{$t[$lc]} = ();
			
			foreach my $z ($lk->getZeros())
			{
				next if ($z->equals($ap->[0]));
				next if ($z->equals($ap->[1]));
				
				if(scalar($z->getPossible()) == 2)
				{
					push @c, [         $z->getPossible() ];
					push @c, [ reverse $z->getPossible() ];

					if(defined($opav{join(',',$z->getPossible())}))
						{ $opav{join(',',$z->getPossible())} = [$z->getRC(),$z];	}
					if(defined($opav{join(',', reverse $z->getPossible())}))
						{ $opav{join(',',reverse $z->getPossible())} = [$z->getRC(),$z];	}
				}
				if(scalar($z->getPossible()) == 3)
				{
					push @{$trip{join(',',sort($z->getPossible()))}},$z;
					
				}
			}
			foreach my $tp ( grep { scalar(@{$trip{$_}}) == 2} keys %trip )
			{
				my @set = split(/,/,$tp);
				push @{$t[$lc]}, [ $set[0], $set[1] ];
				push @{$t[$lc]}, [ $set[1], $set[0] ];
				push @{$t[$lc]}, [ $set[0], $set[2] ];
				push @{$t[$lc]}, [ $set[2], $set[0] ];
				push @{$t[$lc]}, [ $set[1], $set[2] ];
				push @{$t[$lc]}, [ $set[2], $set[1] ];

				if(defined($opav{join(',',$set[0], $set[1])}))
				{
					$opav{join(',',$set[0], $set[1])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[1], $set[0])}))
				{
					$opav{join(',',$set[1], $set[0])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[0], $set[2])}))
				{
					$opav{join(',',$set[0], $set[2])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[0], $set[1])}))
				{
					$opav{join(',',$set[2], $set[0])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[0], $set[1])}))
				{
					$opav{join(',',$set[2], $set[0])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[1], $set[2])}))
				{
					$opav{join(',',$set[1], $set[2])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
				if(defined($opav{join(',',$set[2], $set[1])}))
				{
					$opav{join(',',$set[2], $set[1])} = 
					 [ join(', ',map { $_->getRC() } @{$trip{$tp}}), @{$trip{$tp}}];
				}
			}
			$lc += 1;
		}
				
		foreach my $tset (@t)
		{
			#next unless scalar(@t$set);
			%apv = ();
			foreach my $p0 ($ap->[0]->getPossible())
			{
				foreach my $p1 ($ap->[1]->getPossible())
				{
					next if($p0 == $p1);
					$apv{join(',',$p0,$p1)} = 1;
				}
			}
			
			foreach my $cv (@c)
			{
				my $tc = join(',',@$cv);
				if(defined $apv{$tc})
				{
					delete $apv{$tc};
					#$apv{$tc} = undef;
				}
			}
			foreach my $tv (@$tset)
			{
				my $ttv = join(',',@$tv);
				if(defined $apv{$ttv})
				{
					delete $apv{$ttv};
				}
				#$apv{join(',',@$tv)} = undef;
			}
			
			my @poss1 = map { (split(/,/,$_))[1] } keys %apv;
			my %h0; map { $h0{$_} = 1; } map { (split(/,/,$_))[0] } keys %apv;
			my %h1; map { $h1{$_} = 1; } map { (split(/,/,$_))[1] } keys %apv;
			
			my $answer = 0;
			foreach my $p ($ap->[0]->getPossible())
			{
				next if defined $h0{$p};
				$ap->[0]->setImpossible($p,"APE",$i);
				$ap->[0]->setColor('red',$p);
				$answer = 1;
			}
			foreach my $p ($ap->[1]->getPossible())
			{
				next if defined $h1{$p};
				$ap->[1]->setImpossible($p,"APE",$i);
				$ap->[1]->setColor('red',$p);
				$answer = 1;
			}
			if($answer)
			{
				foreach my $p ($ap->[0]->getPossible())
					{ $ap->[0]->setColor('blue',$p); }
				foreach my $p ($ap->[1]->getPossible())
					{ $ap->[1]->setColor('blue',$p); }
				$fh->print("Allied Pair between ",$ap->[0]->getRC()," and ",$ap->[1]->getRC());
				
				$fh->print("<table border=1><tr><th>Pair</th><th>Found</th><th>Remaining</th>");
				foreach my $ltp (keys %opav)
				{
					$fh->print("<tr>");
					
					$fh->print("<td>$ltp</td><td>$opav{$ltp}[0]</td>");
					if($opav{$ltp}[0] eq '&nbsp;')
					{
						$fh->print("<td>$ltp</td>");
					}
					else
					{
						$fh->print("<td>&nbsp</td>");
						my @zs = @{$opav{$ltp}};
						shift @zs; # get rid of leading location
						foreach my $z (@zs)
						{
							foreach my $c (split(/,/,$ltp))
							{
								$z->setColor('green',$c);
							}
						}
					}
					
					$fh->print("</tr>");
				}
				$fh->print("</table>");
				
				
				return 1;
			}
		}
	}
	0;
}


sub reduceChain
{
	my ($w, $i, $fh) = @_;
	
	foreach my $idx (1 .. 9)
	{
		my %h;
		
		foreach my $l ($w->getLines())
		{
			my @zs = $l->possibleValue($idx);
			if(scalar(@zs) == 2)
			{
				foreach my $z (@zs)
				{
					foreach my $zp (@zs)
					{
						next if($z->equals($zp));
						$h{$z->getXY}{$zp->getXY} = 1;
					}
				}
			}
		}
		
		foreach my $k (keys %h)
		{
			my ($x, $y) = split(/,/,$k);
			my $z = $w->getAtXY($x,$y);
			
			foreach my $l ($z->getLines())
			{
				my @zcs = $l->possibleValue($idx);
				
				foreach my $zc (@zcs)
				{
					next if ($z->equals($zc));
					next if (defined $h{$k}{$zc->getXY});
					$h{$k}{$zc->getXY} = 2;
				}
			}
		}
		
		my %vp = ();
		
		foreach my $k (keys %h)
		{
			foreach my $v (keys %{$h{$k}})
			{
				$vp{$v} = 1;
			}
		}
		my @va = sort keys %vp;
				
		foreach my $k (sort keys %h)
		{
			my %totest = ();
			my %color  = ();
			my %done   = ();
			my $c      = 0;
			
			$totest{$k} = 1;
			$color{$k} = [0,1];
			
#			print "--- $k ---\n";
			
			while(scalar ( grep { not defined $done{$_} } keys %totest  ) )
			{
#				print "loop $idx\n";
				foreach my $tt (grep { not defined $done{$_} } keys %totest)
				{
					$done{$tt} = 1;
					next if( $color{$tt}[0] and $color{$tt}[1]);	# skip if both
					
					if($color{$tt}[0]) { $c = 1; }
					else              { $c = 0; }
#					print "  $tt - $c\n";
					
					foreach my $v (keys %{$h{$tt}})
					{
#						print "    $v ";
						if($h{$tt}{$v} == 1)
						{
							$totest{$v} = 1;
#							print " tt ";
						}
						$color{$v}[$c] = 1;
#						print "[ $color{$v}[0] , $color{$v}[1] ]\n";
					}
				}
			}
			
			my @tonull = grep { $color{$_}[0] and $color{$_}[1] } keys %color;
			
			if(scalar @tonull)
			{
				$fh->print("Chain on $idx eliminates ". join('; ', @tonull) . "<br />");
				foreach my $xy (keys %color)
				{
					#$fh->print("$xy - $color{$xy}[0] $color{$xy}[1]<br />\n");
					my ($x, $y) = split(/,/,$xy);
					my $z = $w->getAtXY($x,$y);
										
					if($color{$xy}[0] and $color{$xy}[1])
					{
						$z->setColor('red',$idx);
						$z->setImpossible($idx,"chain", $i);
					}
					elsif($color{$xy}[0])
					{
						$z->setColor('blue',$idx);
					}
					else
					{
						$z->setColor('green',$idx);
					}
				}
				return 1;
			}
		}
	}
	0;
}

sub reduceYWing
{
	my ($w, $i, $fh) = @_;
	
	my @pairs = grep { scalar($_->getPossible) == 2} $w->getZero;
	
	foreach my $pair (@pairs)
	{
		my @todo;
		my @xp = grep { $_->isPossible(($pair->getPossible())[0]) or
		                $_->isPossible(($pair->getPossible())[1]) }
		         grep { $_->getX == $pair->getX  }
		         grep { not $_->equals($pair)    } @pairs;
		
		my @yp = grep { $_->isPossible(($pair->getPossible())[0]) or
		                $_->isPossible(($pair->getPossible())[1]) }
		         grep { $_->getY == $pair->getY  }
		         grep { not $_->equals($pair)    } @pairs;
		         
	    
	    #build xy sets
	    
	    @todo = ();
	    foreach my $xpi (@xp)
	    {
	    	foreach my $ypi (@yp)
	    	{
	    		push @todo, [$xpi, $ypi];
	    	}
	    }
	    foreach my $to (@todo)
	    {
	    	next if($to->[0]->isPossible( ($pair->getPossible())[0] ) and
	    	        $to->[1]->isPossible( ($pair->getPossible())[0] ));
	    	next if($to->[0]->isPossible( ($pair->getPossible())[1] ) and
	    	        $to->[1]->isPossible( ($pair->getPossible())[1] ));
	    	
	    	my $common = 0;
	    	if( $to->[0]->isPossible( ($to->[1]->getPossible())[0] ) )
	    	{
	    		$common = ($to->[1]->getPossible())[0];
	    	}
	    	if( $to->[0]->isPossible( ($to->[1]->getPossible())[1] ) )
	    	{
	    		$common = ($to->[1]->getPossible())[1];
	    	}
	    	
	    	next if (not $common);
	    	
	    	my ($x1, $y1, $x2, $y2);
	    	$x1 = $to->[0]->getX();
	    	$y1 = $to->[1]->getY();
	    	$x2 = $to->[1]->getX();
	    	$y2 = $to->[0]->getY();
	    	
	    	
	    	my $z1 = $w->getAtXY($x1,$y1);
	    	my $z2 = $w->getAtXY($x2,$y2);
	    	
	    	if($z1->equals($pair))
	    	{
	    		if($z2->isPossible($common))
	    		{
	    			$fh->print("YWing");
	    			$z2->setImpossible($common,"YWing " . $pair->getXY() . "/" . $to->[0]->getXY() . "/" . $to->[1]->getXY(), $i);
	    			$z2->setColor('red',$common,);
	    			
	    			foreach my $p ($pair->getPossible())
	    			{
	    				$pair->setColor('blue',$p);
	    			}
	    			
	    			$to->[0]->setColor("purple",$common);
	    			$to->[1]->setColor("purple",$common);
	    			$to->[0]->setColor('blue', ( grep {$to->[0]->isPossible($_)} $pair->getPossible() )[0]);
	    			$to->[1]->setColor('blue', ( grep {$to->[1]->isPossible($_)} $pair->getPossible() )[0]);
	    			return 1;	# $answer
	    		}
	    	}
	    	else
	    	{
	    		if($z1->isPossible($common))
	    		{
	    			$fh->print("YWing");
	    			$z1->setImpossible($common,"YWing " . $pair->getXY() . "/" . $to->[0]->getXY() . "/" . $to->[1]->getXY(), $i);
	    			$z1->setColor('red',$common,);
	    			
	    			foreach my $p ($pair->getPossible())
	    			{
	    				$pair->setColor('blue',$p);
	    			}
	    			
	    			$to->[0]->setColor("purple",$common);
	    			$to->[1]->setColor("purple",$common);
	    			$to->[0]->setColor('blue', ( grep {$to->[0]->isPossible($_)} $pair->getPossible() )[0]);
	    			$to->[1]->setColor('blue', ( grep {$to->[1]->isPossible($_)} $pair->getPossible() )[0]);
	    			return 1;	# $answer
	    		}
	    	}
	    }
	}
	return 0;
}



sub reduceNakedPair
{
	my ($w, $i, $fh) = @_;
	my $answer = 0;
	my %h;
	
	foreach my $l ($w->getLines())
	{
		%h = ();
		foreach my $z ($l->getZeros())
		{
			next unless ($z->getPossible()) == 2;
			push @{$h{join('',sort $z->getPossible())}}, $z;
		}
		
		foreach my $p (grep { scalar(@{$h{$_}}) == 2 } keys %h)
		{
			my ($v1, $v2) = split(//,$p);
			foreach my $z ($l->getZeros())
			{
				next if $z->equals($h{$p}[0]);
				next if $z->equals($h{$p}[1]);
				if($z->isPossible($v1))
				{
					$z->setImpossible($v1,"Naked Pair $v1",$i);
					$z->setColor('red',$v1);
					$answer = 1;
				}
				if($z->isPossible($v2))
				{
					$z->setImpossible($v2,"Naked Pair $v2",$i);
					$z->setColor('red',$v2);
					$answer = 1;
				}
				if($answer)
				{
					$h{$p}[0]->setColor('blue',$v1);
					$h{$p}[0]->setColor('blue',$v2);
					$h{$p}[1]->setColor('blue',$v1);
					$h{$p}[1]->setColor('blue',$v2);
					return 1;
				}
			}
		}
	}
	
	return $answer;
}

sub reduceHiddenPair
{
	my ($world, $i, $fh) = @_;
	my $answer = 0;
	
	my %h;
	
	foreach my $l ($world->getLines())
	{
		%h = ();
		foreach my $z ($l->getZeros())
		{
			foreach my $p ($z->getPossible())
			{
				push @{$h{$p}}, $z;
			}
		}
	
		my @ps = grep { scalar(@{$h{$_}}) == 2 } keys %h;
		# @ps contains keys where there is a pair in the set
		
		foreach my $p1 (@ps)
		{
			foreach my $p2 (@ps)
			{
				next if ($p1 == $p2);
				my @s = sort ($p1, $p2);
				
				if(($h{$p1}[0]->equals($h{$p2}[0]) and
					$h{$p1}[1]->equals($h{$p2}[1])) or
				   ($h{$p1}[0]->equals($h{$p2}[1]) and
					$h{$p1}[1]->equals($h{$p2}[0])))
				{
					my @pi = grep {not ($_ == $p1 or $_ == $p2)} $h{$p1}[0]->getPossible();
					foreach my $piincr (@pi)
					{
						$h{$p1}[0]->setImpossible($piincr,"Hidden Pair @s",$i);
						$h{$p1}[0]->setColor('red',$piincr);
						$answer = 1;
					}
					@pi = grep {not ($_ == $p1 or $_ == $p2)} $h{$p1}[1]->getPossible();
					foreach my $piincr (@pi)
					{
						$h{$p1}[1]->setImpossible($piincr,"Hidden Pair @s",$i);
						$h{$p1}[1]->setColor('red',$piincr);
						$answer = 1;
					}			
				}
				
				if($answer)
				{
					$h{$p1}[0]->setColor('blue',$p1);
					$h{$p1}[0]->setColor('blue',$p2);
					$h{$p1}[1]->setColor('blue',$p1);
					$h{$p1}[1]->setColor('blue',$p2);
					$fh->print("Hidden Pair @s");
					return $answer;
				}
			}
		}
	}

	return $answer;
}

# Triple forms:
# A - (1,2,3) (1,2,3) (1,2,3) x1
# B - (1,2  ) (1,2,3) (1,2,3) x3
# C - (1,2  ) (  2,3) (1,2,3) x3
# D - (1,2  ) (  2,3) (1,  3) x1

sub reduceNakedtriple
{
	my ($w, $i, $fh) = @_;
	
	foreach my $l ($w->getLines())
	{
		next unless (scalar($l->getZeros()) > 3);	# 4+ to have a trip
		my %p;
		my @p;
		
		foreach my $z ($l->getZeros())
		{
			foreach my $zp ($z->getPossible())
			{
				$p{$zp} = 1;
			}
		}
		@p = keys %p;
		next if (scalar(@p) < 4);
		
		# @p contains missing values in line
		
		my @t = Sudoku::Util::getSubTrip(@p);
		foreach my $tri (@t)
		{
			my %h = ();
			my %t; map { $t{$_} = 1 } @$tri;
			foreach my $z ($l->getZeros())
			{
				foreach my $tt (@$tri)
				{
					if($z->isPossible($tt))
					{
						$h{$z->getXY()} = $z;
					}
				}
			}
			
			if(scalar(keys %h) == 3)
			{
				foreach my $v (values %h)
				{
					my @vp = grep { not defined $t{$_} } $v->getPossible();
					if(scalar @vp)
					{
						foreach my $vps (@vp)
						{
							$v->setImpossible($vps,"hidden tripple @$tri",$i);
							$v->setColor('red',$vps);
						}
						
						foreach my $vh (values %h)
						{
							foreach my $ts (@$tri)
							{
								if($vh->isPossible($ts))
								{
									$vh->setColor('blue',$ts);
								}
							}
						}
						$fh->print("Hidden Tripple @$tri<br />\n");
						return 1;
					}
				}
			}
		}
	}
	0;
}


sub reduceHiddenTriple
{
	my ($w, $i, $fh) = @_;
	
	foreach my $l ($w->getLines())
	{
		next unless (scalar($l->getZeros()) > 3);	# 4+ to have a trip
		my %p;
		my @p;
		
		foreach my $z ($l->getZeros())
		{
			foreach my $zp ($z->getPossible())
			{
				$p{$zp} = 1;
			}
		}
		@p = keys %p;
		next if (scalar(@p) < 4);
		
		# @p contains missing values in line
		
		my @t = Sudoku::Util::getSubTrip(@p);
		foreach my $tri (@t)
		{
			my %h = ();
			my %t; map { $t{$_} = 1 } @$tri;
			foreach my $z ($l->getZeros())
			{
				foreach my $tt (@$tri)
				{
					if($z->isPossible($tt))
					{
						$h{$z->getXY()} = $z;
					}
				}
			}
			
			if(scalar(keys %h) == 3)
			{
				foreach my $v (values %h)
				{
					my @vp = grep { not defined $t{$_} } $v->getPossible();
					if(scalar @vp)
					{						
						foreach my $vps (@vp)
						{
							$v->setImpossible($vps,"hidden tripple @$tri",$i);
							$v->setColor('red',$vps);
						}
						
						foreach my $vh (values %h)
						{
							foreach my $ts (@$tri)
							{
								if($vh->isPossible($ts))
								{
									$vh->setColor('blue',$ts);
								}
							}
						}
						$fh->print("Hidden Tripple @$tri<br />\n");
						return 1;
					}
				}
			}
		}
	}
	0;
}


sub reduceSimple
{
	my ($world, $i,$fh) = @_;
	my $answer = 0;
	
	foreach my $z ($world->getZero())
	{
		foreach my $p ($z->getPossible())
		{
			foreach my $l ($z->getLines())
			{
				my $c = $l->containsV($p);
				if(defined $c and $c)
				{
					$z->setImpossible($p,"found at ". $c->getX . ' ' . $c->getY,$i);
					$z->setColor('red',$p);
					$answer = 1;
				}
			}
		}
	}
	
	return $answer;
}

sub reduceForced
{
	my ($world, $i,$fh) = @_;
	my $answer = 0;
	
	foreach my $z ($world->getZero())
	{
		if(scalar($z->getPossible()) == 1)
		{
			$z->setValue(($z->getPossible())[0]);
			$z->setColor("blue");
			$answer = 1;
		}
	}
	
	return $answer;	
}

sub reduceOnly
{
	my ($world, $i, $fh) = @_;
	my $answer = 0;
	
	REDUCE_ONLY_LOOP:
	foreach my $l ($world->getLines())
	{
		my %h; map { $h{$_} = [] } ( 1 .. 9 );
		foreach my $z (grep { $l->contains($_) } $world->getZero() )
		{
			foreach my $p ( $z->getPossible() )
			{
				push @{$h{$p}}, $z;
			}
		}
		
		foreach my $k ( grep { scalar ( @{$h{$_}} ) == 1 } keys %h )
		{
			my $z = $h{$k}[0];
			$z->setValue($k);
			$z->setColor("blue");
			$answer = 1;
			
			$fh->print("Only $k in unit " . $l->getPrintName() . "<br />\n");
			
			last REDUCE_ONLY_LOOP;
		}
	}
	
	$answer;
}

sub reduceIntersect
{
	my ($world, $i, $fh) = @_;
	my $answer = 0;
	my %h;
	
	foreach my $l ($world->getLines())
	{
		foreach my $v ( 1 .. 9 )
		{
			$h{$l->getName()}{$v} = [ $l->possibleValue($v) ];
		}
	}
	
	# if s3 contains all the '4' associated with y1, then remove all other 4 from s3
		
	LINE_KEY:
	foreach my $lk ( keys %h )
	{
		LINE:
		foreach my $l ($world->getLines())
		{
			next LINE if ($lk eq $l->getName());
			next LINE if ($lk =~ /X/ and $l->getName() =~ /Y/);
			next LINE if ($lk =~ /Y/ and $l->getName() =~ /X/);
			# if there is an intersect of X and Y, then it will be an only
			
			foreach my $vk ( sort keys %{$h{$lk}} )	# 1 .. 9
			{
				my $match = 1;
				my $loopo = 0;
				foreach my $p ( @{$h{$lk}{$vk}} )
				{
					$loopo = 1;
					#$p->print();
					if(not $l->contains($p))
					{
						$match = 0;
					}
				}
				
				if($match and $loopo)
				{
					# print("match on $lk and ",$l->getName()," with $vk\n");
					
					# find the intersection of squares not matched in $l
					
					my @p1 = @{$h{$lk}{$vk}};
					my @p2 = $l->possibleValue($vk);
					
					foreach my $p ( @p1 )
					{
						@p2 = grep { not $_->equals($p) } @p2;
						$p->setColor('blue',$vk);
					}
					
					if(scalar @p2)
					{
						$fh->print("locked set in ", $l->getPrintName($lk)," removes all other $vk from ",$l->getPrintName(),"\n");
						#print " " . scalar(@p2) . " items to be removed from " .
						#      $l->getName() . " for $vk\n";
						foreach my $p2k (@p2)
						{
							
							#$p2k->print();
							$p2k->setImpossible($vk,"$vk locked in $lk",$i);
							$p2k->setColor('red',$vk);
						}
						$answer = 1;
						last LINE_KEY;
					}
					else
					{
						foreach my $p (@p1)
						{
							$p->resetColor();
						}
					}
				}
			}
		}
	}
	$answer;
}

sub reduceXWing
{
	my ($world, $i, $fh) = @_;
	my $answer = 0;
	
	my %h;
	
	# rows
	
	foreach my $l ( grep { $_->getName() =~ m/Y/ } $world->getLines() )
	{
		my %lh;
		foreach my $z ( grep { $l->contains($_) } $world->getZero() )
		{
			foreach my $p ( $z->getPossible() )
			{
				push @{$lh{$p}} , $z;
			}
		}
		
		foreach my $lhk ( grep { scalar(@{$lh{$_}}) == 2 } keys %lh )
		{
			foreach my $z ( @{$lh{$lhk}} )
			{
				$h{$lhk}{$z->getX . ',' . $z->getY} = 1;
			}
		}
	}
	
	foreach my $k ( sort keys %h )
	{		
		foreach my $sk ( keys %{$h{$k}} )
		{
			my ($x, $y);
			($x, $y) = split(/,/, $sk);
			foreach my $cp (keys %{$h{$k} } )
			{
				my ($sx, $sy);
				($sx, $sy) = split(/,/,$cp);
				
				next if($sx == $x);
				next if($sy == $y);
				
				next unless defined $h{$k}{$sx . ',' . $y};
				next unless defined $h{$k}{$x  . ',' . $sy};
				

				my $z;
				my $l;
				my @zs;
				
				$z = $world->getAtXY($x,$y);
				$l = (grep { $_->getName() =~ m/X/ } $z->getLines)[0];
				@zs = $l->getZeros();
				@zs = grep {not( ($_->getX == $x  and $_->getY == $y ) or
				                 ($_->getX == $sx and $_->getY == $y ) or
				                 ($_->getX == $x  and $_->getY == $sy) or
				                 ($_->getX == $sx and $_->getY == $sy) ) 
				           } @zs;
				@zs = grep { $_->isPossible($k) } @zs;

				foreach my $zi (@zs)
				{
					$zi->setImpossible($k,"XWing via row with $x,$y $sx,$sy",$i);
					$zi->setColor('red',$k);
					$answer = 1;
				}
				
				$z = $world->getAtXY($sx,$sy);
				$l = (grep { $_->getName() =~ m/X/ } $z->getLines)[0];
				@zs = $l->getZeros();
				@zs = grep {not( ($_->getX == $x  and $_->getY == $y ) or
				                 ($_->getX == $sx and $_->getY == $y ) or
				                 ($_->getX == $x  and $_->getY == $sy) or
				                 ($_->getX == $sx and $_->getY == $sy) ) 
				           } @zs;
				@zs = grep { $_->isPossible($k) } @zs;

				foreach my $zi (@zs)
				{
					$zi->setImpossible($k,"XWing via row with $x,$y $sx,$sy",$i);
					$zi->setColor('red',$k);
					$answer = 1;
				}
				
				if($answer)
				{
					my @p = map { "r".($_->[1]+1)."c".($_->[0]+1) } 
					            ( [$x,$y], [$x,$sy], [$sx,$sy], [$sx,$y] );
					$fh->print("XWing @p -- $k across rows<br />");
					$world->getAtXY($x,$y)->setColor('blue',$k);
					$world->getAtXY($x,$sy)->setColor('blue',$k);
					$world->getAtXY($sx,$y)->setColor('blue',$k);
					$world->getAtXY($sx,$sy)->setColor('blue',$k);
					
					return $answer;
				}
			}
		}
		
	}
	
	
	# columns
	foreach my $l ( grep { $_->getName() =~ m/X/ } $world->getLines() )
	{
		my %lh;
		foreach my $z ( grep { $l->contains($_) } $world->getZero() )
		{
			foreach my $p ( $z->getPossible() )
			{
				push @{$lh{$p}} , $z;
			}
		}
		
		foreach my $lhk ( grep { scalar(@{$lh{$_}}) == 2 } keys %lh )
		{
			foreach my $z ( @{$lh{$lhk}} )
			{
				$h{$lhk}{$z->getX . ',' . $z->getY} = 1;
			}
		}
	}
	
	foreach my $k ( sort keys %h )
	{		
		foreach my $sk ( keys %{$h{$k}} )
		{
			my ($x, $y);
			($x, $y) = split(/,/, $sk);
			foreach my $cp (keys %{$h{$k} } )
			{
				my ($sx, $sy);
				($sx, $sy) = split(/,/,$cp);
				
				next if($sx == $x);
				next if($sy == $y);
				
				next unless defined $h{$k}{$sx . ',' . $y};
				next unless defined $h{$k}{$x  . ',' . $sy};
				

				my $z;
				my $l;
				my @zs;
				
				$z = $world->getAtXY($x,$y);
				$l = (grep { $_->getName() =~ m/Y/ } $z->getLines)[0];
				@zs = $l->getZeros();
				@zs = grep {not( ($_->getX == $x  and $_->getY == $y ) or
				                 ($_->getX == $sx and $_->getY == $y ) or
				                 ($_->getX == $x  and $_->getY == $sy) or
				                 ($_->getX == $sx and $_->getY == $sy) ) 
				           } @zs;
				@zs = grep { $_->isPossible($k) } @zs;

				foreach my $zi (@zs)
				{
					$zi->setImpossible($k,"XWing via col with $x,$y $sx,$sy",$i);
					$zi->setColor('red',$k);
					$answer = 1;
				}
				
				$z = $world->getAtXY($sx,$sy);
				$l = (grep { $_->getName() =~ m/X/ } $z->getLines)[0];
				@zs = $l->getZeros();
				@zs = grep {not( ($_->getX == $x  and $_->getY == $y ) or
				                 ($_->getX == $sx and $_->getY == $y ) or
				                 ($_->getX == $x  and $_->getY == $sy) or
				                 ($_->getX == $sx and $_->getY == $sy) ) 
				           } @zs;
				@zs = grep { $_->isPossible($k) } @zs;

				foreach my $zi (@zs)
				{
					$zi->setImpossible($k,"XWing via col with $x,$y $sx,$sy",$i);
					$zi->setColor('red',$k);
					$answer = 1;
				}
				
				if($answer)
				{
					my @p = map { "r".($_->[1]+1)."c".($_->[0]+1) } 
					            ( [$x,$y], [$x,$sy], [$sx,$sy], [$sx,$y] );
					$fh->print("XWing @p -- $k across columns<br />");
					$world->getAtXY($x,$y)->setColor('blue',$k);
					$world->getAtXY($x,$sy)->setColor('blue',$k);
					$world->getAtXY($sx,$y)->setColor('blue',$k);
					$world->getAtXY($sx,$sy)->setColor('blue',$k);
					
					return $answer;
				}
			}
		}
	}
	
	# Square
	
	$answer;
}
