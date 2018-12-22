<?php
if(!isset($_GET['id'])){
	echo('ID not set!');
	exit;
}
$ID = htmlspecialchars($_GET['id']);
$Text = "<center><br>\r\n\t<img src=\"https://antiscan.me/images/result/$ID.png\">\r\n</center>";
file_put_contents("tabs/detections.html", $Text, LOCK_EX);
echo('Success.');
?>