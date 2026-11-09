#!/opt/lampp/bin/perl
use DBI;

print "Content-Type: text/html\n\n";

my $dsn="dbi:Oracle:host=localhost;sid=xe";
my $dbh=DBI->connect("$dsn","hr","geheim") or
        die "Kann Datenbank nicht erreichen!";

print "<html>";
print "<head>";
print "<title>Perl und Oracle</title>";
print "</head>";
print "<body>";
print "<h1>Perl und Oracle</h1>";
print "<table border=\"1\">";
print "<tr>";
print "<th>Interpret</th>";
print "<th>Titel</th>";
print "<th>Jahr</th>";
print "</tr>";

my $query="SELECT * FROM cds";

my $prep_sql=$dbh->prepare($query) or  die print "Can't prepare";
$prep_sql->execute() or  die print "Can't  execute";

while (my @row = $prep_sql->fetchrow_array())
{
    print "<tr>";
    print "<td>".$row[2]."</td>";
    print "<td>".$row[1]."</td>";
    print "<td>".$row[3]."</td>";
    print "</tr>";
}

$prep_sql->finish();
$dbh->disconnect();

print "</table>";
print "</body>";
print "</html>";
