#!/usr/local/bin/perl -w

# парсер NAT-events в формате, в котором их показывает nfdump
# (c) chpoqxie gmail com

use strict;
use warnings;
use Time::Local;

open(TaskList, "<./tasks.txt") or die ("--- не вижу списка задач\n");

while(my $task = <TaskList>) {
	chomp $task;
	my @tdata = split(/\ /, $task);

	# $tdata[0] - номер задачи
	# $tdata[1] - имя файла, откуда брать данные
	# $tdata[2] - год
	# $tdata[3] - месяц
	# $tdata[4] - день
	# $tdata[5] - час
	# $tdata[6] - минута
	# $tdata[7] - секунда
	# $tdata[8] - ip NATа

	my $src_file = "search".$tdata[1];

	# время поиска в формате сек-мин-час-день-месяц-год (timelocal считает месяцы с нуля до 11)
#	my $searchtime = timelocal( 49, 1, 0, 20, (12-1), 23 );
	my $searchtime = timelocal( $tdata[7], $tdata[6], $tdata[5], $tdata[4], ($tdata[3]-1), $tdata[2] );

	open(FILE, $src_file) or die "Can't open file $src_file\n";

	my %DATA;

	LINE: while( <FILE> )
	{

	#2023-04-14 04:47:46.348     ADD 6      abonent-grey-IP:14798 ->   destination-IP:80           my-NAT-IP:14798 ->   destination-IP:80

	#	1	2	3		4	5	6	7   8    9     10   11	   12	   13    14	  15     16       17   18     19       20   21       22    23        24
	if ( /^(\d{4})\-(\d{2})\-(\d{2})\ (\d{2}):(\d{2}):(\d{2})\.(\d{3})(\s+)(\w+)\ (\d+)(\s+)([\.\d]+)\:(\d+)(\s+)\-\>(\s+)([\.\d]+)\:(\d+)(\s+)([\.\d]+)\:(\d+)(\s+)\-\>(\s+)([\.\d]+)\:(\d+)/ )
	{
		my ( $yy, $mm, $dd, $h, $m, $s, $ms, $action, $proto, $clientip, $clientport, $dstip1, $dstport1, $natip, $natport, $dstip2, $dstport2 )
		= ( $1, $2, $3, $4, $5, $6, $7, $9, $10, $12, $13, $16, $17, $19, $20, $23, $24 );

		my $utime = timelocal( $s, $m, $h, $dd, ($mm-1), $yy );
		my $key = $clientip."_".$clientport."_".$dstip1."_".$dstport1."_".$natip."_".$natport."_".$dstip2."_".$dstport2;
		my $value = $utime;

		$DATA{$key}{$action} .= $value;
	}

	}
	close ( FILE );

	foreach my $key ( keys %DATA )
	{
		my ( $CLIIP, $CLIPORT, $DSTIP1, $DSTPORT1, $NATIP, $NATPORT, $DSTIP2, $DSTPORT2 ) = split( /_/, $key );
	# допусловия
		if ( (( $NATIP eq $tdata[8] ) and ( $DSTIP2 eq "217.20.155.13" )) or (( $NATIP eq $tdata[8] ) and ( $DSTIP2 eq "217.20.147.1" )) or (( $NATIP eq $tdata[8] ) and ( $DSTIP2 eq "5.61.23.11" )) )
		{
			if ( !exists( $DATA{$key}{"ADD"} ) )
			{
#				print $key."_-_ADDnone\n";
				$DATA{$key}{"ADD"} = 1577826060;	# 1 января 2020 года
			}
			if ( !exists( $DATA{$key}{"DELETE"} ) )
			{
#				print $key."_-_DELnone\n";
				$DATA{$key}{"DELETE"} = 1893445260;	# 1 января 2030 года
			}
			if ( ( $DATA{$key}{"ADD"} <= $searchtime ) && ( $DATA{$key}{"DELETE"} >= $searchtime ) )
			{
				open(ResFile, ">>", "./result".$tdata[0].".txt") or die ("--- не могу записать результат\n");
				print ResFile $CLIIP."\n";
				close ResFile;
			}
		}
	}

}
