<?php
	include_once("XML/sql2xml.php");

	$sql2xml = new xml_sql2xml("mysql://root@localhost/cdcol");
	$xml = $sql2xml->getxml("select * from cds");
	
	header("Content-Type: text/xml;");
	echo $xml;
?>
