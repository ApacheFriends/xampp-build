<?php
	header("Content-Type: text/html; charset=utf-8;");
?>
<html>
<head>
<title>PHP und XML_RSS</title>
</head>
<body>
<?php
	include_once("XML/RSS.php");

	$rss =& new XML_RSS('http://www.heise.de/newsticker/heise.rdf');

	$rss->parse();

	$meta=$rss->getChannelInfo();

	echo "<h1>{$meta['title']}</h1>";
	echo $meta['description'];
	echo "<br>";
	echo "<a href=\"{$meta['link']}\">mehr...</a>";
	echo "<p>";

	foreach ($rss->getItems() as $item) 
	{
		echo "<a href=\"{$item['link']}\">{$item['title']}</a><br>";
	}

?>
</body>
</html>
