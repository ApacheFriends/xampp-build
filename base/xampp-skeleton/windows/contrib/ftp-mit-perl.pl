use Net::FTP;
print "Content-Type: text/html\n\n";
$ftp = Net::FTP->new("localhost");	# Unser Host
die "Konnte keine Verbindung aufbauen $!" unless $ftp;
$ftp->login("newuser", "wampp");	# Hier Benutzername und Password eingeben			
$ftp->get("index.php");
$ftp->quit;
