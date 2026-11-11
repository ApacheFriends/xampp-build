<?php
	$host = "127.0.0.1";
	$timeout = 1;
	$i = 1;

	$curdir = getcwd();
	$curdir = getcwd();
	list($partition, $nonpartition) = preg_split ("/:/", $curdir); //Fix by Wiedmann
	$partwampp = substr(realpath(__FILE__), 0, strrpos(dirname(realpath(__FILE__)), '\\'));
	
	$portchecklog = $partwampp."\install\\portcheck.ini";

	$port = ereg_replace('-', '', $argv[1]);
	$werte = substr_count($port, ',');
	$ports = explode(',', $port);
	$anzahl = count($ports);
	$datei = fopen($portchecklog, 'w+');
	fputs($datei, "[Ports]\r\n");
	while ($i <= $anzahl) {
		$a = $i - 1;

		settype($ports[$a], "integer");
		if (($handle = @fsockopen($host, $ports[$a], $errno, $errstr, $timeout)) == false) {
			$print = "Port".$ports[$a]."=FREE\r\n";
		} else {
			$print = "Port".$ports[$a]."=BLOCKED\r\n";
		}
		fputs($datei, $print);
		@fclose($handle);
		$i++;
	}
	fclose($datei);
	exit;
?>
