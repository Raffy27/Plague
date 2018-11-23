<?php
session_start();
if(isset($_SESSION['user'])){
	header('Location: dashboard.php');
	exit;
}
?>
<html>
    <head>
		<link href="https://fonts.googleapis.com/css?family=Krub" rel="stylesheet">
		<title>Project Plague</title>
		<link rel="shortcut icon" type="image/png" href="img/favicon.png"/>
		<link rel="stylesheet" type="text/css" href="style.css">
	</head>
    <body>
        <div class="loginbox">
        <img src="img/icon.png" class="avatar">
           <h1>Project Plague</h1>
           <form action="login.php" method="post">
               <p>Username</p>
               <input type="text" name="user">
               <p>Password</p>
               <input type="password" name="pass">
               <input type="submit" name="" value="Login">
           <a href="#">Lost your password?</a><br>
		   <a href="#">Register</a><br>
           </form>
        </div>
    </body>
</html>