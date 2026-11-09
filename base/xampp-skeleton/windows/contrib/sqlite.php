<html>
<head>
<title>PHP und SQLite</title>
</head>
<body>
<h1>PHP und SQLite</h1>
<table border="1">
<tr>
    <th>Interpret</th>
    <th>Titel</th>
    <th>Jahr</th>
</tr>
<?php
    $db = sqlite_open('../sqlite/cdcol', '0666');

    $query = "SELECT * FROM cds";
    $result = sqlite_query($db,$query);
    if ($result) 
    {
        while ($row = sqlite_fetch_array($result))
        {
            echo "<tr>";
            echo "<td>".$row['interpret']."</td>";
            echo "<td>".$row['titel']."</td>";
            echo "<td>".$row['jahr']."</td>";
            echo "</tr>";
        }
    }
    else
    {
        echo sqlite_error_string(sqlite_last_error($db));
    }

?>
</table>
</body>
</html>
