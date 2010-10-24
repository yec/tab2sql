#!/bin/bash
# Generate sql statements from tab seperated file

cat $1 \
| awk '
BEGIN {
	FS="\t";
	OFS="\t";
}

{
	gsub(/\r|\n|\"/,"",$0);
}

(NR == 1) {
	for ( i=1 ; i <= NF ; i++ )
	{
		if($i ~ /Addr/) { addr = substr($i,0,6);}
		if (($i ~ /(Line|City|State|Postcode|Country|Phone|Fax|Email|WWW|Contact|Salutation)/) && ($i !~ /Line 1/)) {$i = addr $i;}

		if($i ~ /Terms/) { addr = substr($i,0,7);}
		if ($i ~ /(Discount|Due Days|Charge)/) {$i = addr $i;}
	}
	print tolower($0);
}
(NR > 1) {print}

' \
| sed '1 s/[^\ta-z0-9]//ig' > clean.$1


cat clean.$1 \
| awk '
BEGIN {FS="\t"}

(NR == 1){
	for(i=1;i <= NF ; i++)
	{
		T[i] = $i;


		if (tolower($i) ~ /id$/ && tolower($i) !~ /paid/)
		{
			Type[i] = "INT";
			Null[i] = "NULL";
		}
		else { Type[i] = "VARCHAR"; Null[i] = "NOT NULL"}
	}

	fieldsnumber = NF;
}

(NR > 1) {
	for( i=1 ; i <= NF ; i++)
	{
		if (length($i) > L[i] )
		{
			L[i] = length($i);
		}
	}
}

END {
	print "DROP TABLE IF EXISTS `'$2'`; CREATE TABLE `'$2'` (";

	comma = "";

	for( i=1;i <= fieldsnumber ; i++ )
	{
		if(i > 1){comma = ", "}

		print comma "`" T[i] "` " Type[i] "(" L[i] + 10 ") " Null[i];
	}

	print ");";

}
' > $2.sql

cat clean.$1 \
| awk '
BEGIN{
	FS="\t";
	print "INSERT INTO '$2' (";
}

(NR == 1 ) {
	OFS= ", ";
	for(i=1;i<=NF;i++){$i = "`"$i"`"}
	print $0 " ) VALUES";
}

( NR > 1 && NF > 0) {
	OFS= ", ";
	comma = "";

	if (NR > 2)
	{comma = ", ";}
	gsub(/\n|\r|\"/,"",$0);
	for(i = 1;i <= NF; i++)
	{
		$i = "\""$i"\"";
	}
	print comma "(" $0 ")";
}
END{print ";"}
' >> $2.sql
