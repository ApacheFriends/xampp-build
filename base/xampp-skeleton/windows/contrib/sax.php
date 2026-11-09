<html>
<head>
<title>PHP und SAX</title>
</head>
<body>
<h1>PHP und SAX</h1>
<table border="1">
<tr>
    <th>Titel</th>
    <th>Interpret</th>
    <th>Jahr</th>
    <th>ID</th>
</tr>
<?php
    $parser = xml_parser_create();
    xml_set_element_handler($parser, 'startE','endE');
    xml_set_character_data_handler($parser, 'characterD');
    $fp = fopen('cds.xml', 'r');
    while ($data = fread($fp, 1024))
    {
        $result = xml_parse($parser, $data);
    } 
    fclose($fp);

    function startE($parser, $name, $attribs)
    {
	if($name=="ROW")
	{
		echo "<tr>";
	}
	else if($name=="TITEL" || $name=="INTERPRET" || $name=="JAHR" || $name=="ID")
	{
		echo "<td>";
	}
    } 

    function endE($parser, $name)
    {
	if($name=="ROW")
	{
		echo "</tr>";
	}
	else if($name=="TITEL" || $name=="INTERPRET" || $name=="JAHR" || $name=="ID")
	{
		echo "</td>";
	}
    } 

    function characterD($parser, $data)
    {
        print $data;
    }
?>
</table>
</body>
</html>
