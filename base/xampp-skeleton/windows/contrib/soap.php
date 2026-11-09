<?php
	header("Content-Type: text/html; charset=utf-8;");
?>
<html>
<head>
<title>PHP und SOAP</title>
</head>
<body>
<?php

    $client = new SoapClient('http://api.google.com/GoogleSearch.wsdl');
    
    $apikey="apikey hier einsetzen";
    $searchfor="xampp";

    $result = $client->doGoogleSearch($apikey, $searchfor, 0, 10, false, '', true, '', '', '');
    
    echo "Gefundene Seiten: ".$result->estimatedTotalResultsCount;

    echo "<ol>";
    foreach ($result->resultElements as $hit) 
    {
        echo "<li><a href=\"".$hit->URL."\">".$hit->title."</a>";
        echo "<br>".$hit->snippet;
    }
    echo "</ol>";
?>
</body>
</html>
