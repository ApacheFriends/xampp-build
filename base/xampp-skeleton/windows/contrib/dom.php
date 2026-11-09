<?php

    $dom = new DOMDocument('1.0', 'iso-8859-1');

    $root = $dom->createElement('cds');
    $dom->appendChild($root);

    mysql_connect("localhost","root","");
    mysql_select_db("cdcol");

    $result=mysql_query("SELECT id,titel,interpret,jahr FROM cds ORDER BY interpret;");
    
    while( $row=mysql_fetch_array($result) )
    {
	    $cd = $dom->createElement('cd');
	    $cd->setAttribute('id', $row['id']);

	    $titel = $dom->createElement('titel');
	    $titel->appendChild($dom->createTextNode($row['titel']));
	    $cd->appendChild($titel);

	    $interpret = $dom->createElement('interpret');
	    $interpret->appendChild($dom->createTextNode($row['interpret']));
	    $cd->appendChild($interpret);

	    $jahr = $dom->createElement('jahr');
	    $jahr->appendChild($dom->createTextNode($row['jahr']));
	    $cd->appendChild($jahr);

	    $root->appendChild($cd);
    }

    header("Content-Type: text/xml;");
	$xml="<?xml version=\"1.0\" encoding=\"ISO-8859-1\" ?> 
<rss version=\"2.0\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" xmlns:admin=\"http://webns.net/mvcb/\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:slash=\"http://purl.org/rss/1.0/modules/slash/\" xmlns:wfw=\"http://wellformedweb.org/CommentAPI/\" xmlns:content=\"http://purl.org/rss/1.0/modules/content/\">
<channel>
";
echo $xml;
print $dom->saveXML();
echo "</channel></rss>";
?>
