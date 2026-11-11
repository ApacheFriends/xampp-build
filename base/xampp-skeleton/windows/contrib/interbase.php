<html>
<head>
<title>PHP und InterBase</title>
</head>
<body>
<h1>PHP und InterBase/Firebird</h1>
<table border="1">
<tr>
    <th>Interpret</th>
    <th>Titel</th>
    <th>Jahr</th>
</tr>
<?php
    $db = ibase_pconnect("/opt/lampp/var/firebird/cdcol.gdb", "oswald", "geheim");

    $query = "SELECT * FROM cds";
    $result = ibase_query($query);
    if ($result) {
        while ($row = ibase_fetch_assoc  ($result))
        {
            echo "<tr>";
            echo "<td>".$row['INTERPRET']."</td>";
            echo "<td>".$row['TITEL']."</td>";
            echo "<td>".$row['JAHR']."</td>";
            echo "</tr>";
        }
    }
    else
    {
        echo ibase_errmsg();
    }

?>
</table>
</body>
</html>
