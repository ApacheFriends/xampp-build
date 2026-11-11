#!/opt/lampp/bin/perl
use DBI;

my $dsn = 'DBI:mysql:cdcol:localhost';
my $db_user_name = 'root';
my $db_password = '';
my ($id, $password);
my $dbh = DBI->connect($dsn, $db_user_name, $db_password);

my $sth = $dbh->prepare(qq{
	SELECT id,titel,interpret,jahr FROM cds ORDER BY interpret;
});
$sth->execute();

while (my ($id, $title, $interpret, $jahr ) = 
    $sth->fetchrow_array()) 
{
     print "$title, $interpret\n";
}
$sth->finish();

