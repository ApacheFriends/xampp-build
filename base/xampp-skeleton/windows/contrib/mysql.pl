#!/opt/lampp/bin/perl
use DBI;

print "Content-Type: text/html\n\n";

my $dsn="dbi:mysql:phonebook:localhost";
my $dbh=DBI->connect("$dsn","oswald","geheim") or
        die "Kann Datenbank nicht erreichen!";

print "<html>";
print "<head>";
print "<title>Perl und MySQL</title>";
print "</head>";
print "<body>";
print "<h1>Perl und MySQL</h1>";
print "<table border=\"1\">";
print "<tr>";
print "<th>Vorname</th>";
print "<th>Nachname</th>";
print "<th>Telefonnummer</th>";
print "</tr>";

my $query="SELECT * FROM users";

my $prep_sql=$dbh->prepare($query) or  die print "Can't prepare";
$prep_sql->execute() or die print "Can't  execute";

while (my @row = $prep_sql->fetchrow_array())
{
    print "<tr>";
    print "<td>".$row[1]."</td>";
    print "<td>".$row[2]."</td>";
    print "<td>".$row[3]."</td>";
    print "</tr>";
}

$prep_sql->finish();
$dbh->disconnect();

print "</table>";
print "</body>";
print "</html>";
