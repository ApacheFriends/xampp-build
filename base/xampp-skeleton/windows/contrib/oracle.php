<html>
<head>
<title>PHP und Oracle</title>
</head>
<body>
<h1>PHP und Oracle</h1>
<table border="1">
<tr>
    <th>Interpret</th>
    <th>Titel</th>
    <th>Jahr</th>
</tr>
<?php
    $db="(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(PROTOCOL=TCP)
       (HOST=localhost) (PORT=1521)))
       (CONNECT_DATA=(SERVICE_NAME=xe)))";

    // Oracle 10g
    //$db="//localhost/xe";

    $c=ocilogon("hr", "geheim", $db);

    $s = ociparse($c, "SELECT * FROM cds");

    if(ociexecute($s))
    {
        while (ocifetch($s)) 
        {
            echo "<tr>";
            echo "<td>".ociresult($s, "INTERPRET")."</td>";
            echo "<td>".ociresult($s, "TITEL")."</td>";
            echo "<td>".ociresult($s, "JAHR")."</td>";
            echo "</tr>";
        }
    }
    else
    {
	$e = oci_error($s); 
        echo htmlentities($e['message']);
    }
?>
</table>
</body>
</html>

