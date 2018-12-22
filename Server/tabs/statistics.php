<?php

$InfCount = array();
$Infections = array();
$UserCount = 0;

function GetLabels(){
	global $InfCount, $UserCount;
	$S = "";
	$Loop = 1;
	foreach($InfCount as $u => $c){
		$S .= "\"$u\"";
		if($Loop<$UserCount) $S .= ", ";
		$Loop++;
	}
	return $S;
}

function GetCounts(){
	global $InfCount, $UserCount;
	$S = "";
	$Loop = 1;
	foreach($InfCount as $u => $c){
		$S .= "$c";
		if($Loop<$UserCount) $S .= ", ";
		$Loop++;
	}
	return $S;
}

function GetColors(){
	global $UserCount;
	$S = "";
	for($i = 1; $i<$UserCount; $i++){
		$S .= '"hsl(' . rand(0, 360) . ', 70%, 61%)", ';
	}
	$S .= '"hsl(' . rand(0, 360) . ', 70%, 61%)"';
	return $S;
}

function WhoInfected($GUID, $InfBy){
	global $InfCount, $Infections;
	if(!array_key_exists($InfBy, $InfCount)){ //If the InfectedBy value is not a user
		return WhoInfected($InfBy, $Infections[$InfBy]); //Then see who infected the computer which infected this computer
	} else return $InfBy;
}

include('data.php');
if(!ConnectDB('plague')){
	die('Failed to connect to the database.');
}

//Build user list
$Sql = "SELECT Username FROM users;";
$Result = $Conn->query($Sql);
if($Result->num_rows > 0){
	while($Entry = $Result->fetch_assoc()){
		$InfCount[$Entry['Username']] = 0;
		$UserCount++;
	}
}

//Build infection map
$Sql = "SELECT GUID, Infected, LastSeen FROM clients;";
$Result = $Conn->query($Sql);
if($Result->num_rows > 0){
	while($Entry = $Result->fetch_assoc()){
		$Infections[$Entry['GUID']] = $Entry['Infected'];
	}
}

foreach($Infections as $x => $y){
	$InfCount[WhoInfected($x, $y)]++;
}

?>
<canvas id="infectionChart" style="max-width: 50%;"></canvas>
<div style="height: 100px;"></div>
<p>Number of registered users: <font color="#aaf444"><?php echo($UserCount); ?></font></p>
<p>Number of infected clients: <font color="#aaf444"><?php echo($Result->num_rows); ?></font></p>
<!-- Number of online and offline clients -->
<script src="scripts/Chart.min.js"></script>
<script>
var ctx = $("#infectionChart");
var infChart = new Chart(ctx, {
    type: "doughnut",
    data: {
      labels: [<?php echo(GetLabels()); ?>],
      datasets: [
        {
          label: "Infections",
          backgroundColor: [<?php echo(GetColors()); ?>],
          data: [<?php echo(GetCounts()); ?>]
        }
      ]
    },
    options: {
      title: {
        display: true,
		fontFamily: "Krub, sans-serif",
		fontColor: "#aaf444",
		fontSize: 15,
        text: "Infection Spread Summary"
      },
	  legend: {
		  labels: {
			  fontFamily: "Krub, sans-serif",
			  fontColor: "#ffffff",
			  fontSize: 13
		  }
	  }
    }
});

</script>
