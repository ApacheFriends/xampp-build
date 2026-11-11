<html>
<head>
<title>PHP und PostgreSQL</title>
</head>
<body>
<h1>PHP und PostgreSQL</h1>
<table border="1">
<tr>
    <th>Interpret</th>
    <th>Titel</th>
    <th>Jahr</th>
</tr>
<?php

    $conn_string = "host=localhost port=5432 dbname=cdcol  
                    user=oswald password=geheim";

    $db_handle = pg_connect($conn_string);
    if(!$db_handle)
        die("Kann Datenbank nicht erreichen!");

    $query = "SELECT * FROM cds";

    $result = pg_exec($db_handle, $query);

    if (!$result) 
    {
        echo pg_errormessage($db_handle);
    }
    else
    {
        for ($row = 0; $row < pg_numrows($result); $row++)
        {
            $values = pg_fetch_array($result, $row, PGSQL_ASSOC);
            echo "<tr>";
            echo "<td>".$values['interpret']."</td>";
            echo "<td>".$values['titel']."</td>";
            echo "<td>".$values['jahr']."</td>";
            echo "</tr>";
        }
    }
?>
</table>
</body>
</html>
