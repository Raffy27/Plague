<?php
define('SALT', 'S4ltk33p3r');

session_start();

//Check if user is already logged in
if(isset($_SESSION['user'])){
	header('Location: dashboard.php');
	exit;
}
//Check if login details were supplied
if(!isset($_POST['user'])){
	header('Location: index.php');
	exit;
} else $_User = htmlspecialchars($_POST['user']);
if(!isset($_POST['pass'])){
	header('Location: index.php');
	exit;
} else $_Pass = strtoupper(hash('sha256', $_POST['pass'] . SALT));

include('data.php');
if(!ConnectDB('plague')){
	http_response_code(500);
	die('Failed to connect to the database.');
}

if(UserValid($_User, $_Pass)){
	$_SESSION['user'] = $_User;
	if(!isset($_POST['builder']))
	  header('Location: dashboard.php');
    else echo('Success');
} else {
	if(!isset($_POST['builder']))
	  header('Location: index.php');
    else echo('Failed');
}

?>