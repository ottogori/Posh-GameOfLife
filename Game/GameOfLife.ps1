﻿Function Initialize-Host{
	Param(
		[Parameter(Mandatory=$false)]$wndTitle = "Game of Life...",
		[Parameter(Mandatory=$false)][Int]$wndWidth=50,
		[Parameter(Mandatory=$false)][Int]$wndHeight=50
	)
	$wndSize = $Host.UI.RawUI.WindowSize
	$wndSize.Width = $wndWidth
	$wndSize.Height = $wndHeight
	
	$wndBuffSize = $wndSize
	
	#Set Console
	$Host.UI.RawUI.WindowTitle = $wndTitle
	$Host.UI.RawUI.WindowSize  = $wndSize
	$Host.UI.RawUI.BufferSize  = $wndBuffSize
	$Host.UI.RawUI.CursorSize  = 0
	$Host.UI.RawUI.ForegroundColor = "Green"
	$Host.UI.RawUI.BackgroundColor = "Black"

	#get a clear the screen.
	Clear-Host
}

Function Push-Host{
	#Get the full buffer
	$hostRect       = "System.Management.Automation.Host.Rectangle"
	$bufferObject   = New-Object $hostRect 0, 0, $(($Host.UI.RawUI.BufferSize).Width), $(($Host.UI.RawUI.BufferSize).Height)
	
	$SCRIPT:hostProperties= @{
    	"Title"           = $Host.UI.RawUI.WindowTitle
		"WindowSize"      = $Host.UI.RawUI.WindowSize
    	"WindowPosition"  = $Host.UI.RawUI.WindowPosition 
    	"BufferSize"      = $Host.UI.RawUI.BufferSize    
    	"Buffer"          = $Host.UI.RawUI.GetBufferContents($bufferObject)    
    	"Background"      = $Host.UI.RawUI.BackgroundColor    
    	"Foreground"      = $Host.UI.RawUI.ForegroundColor
    	"CursorSize"      = $Host.UI.RawUI.CursorSize
    	"CursorPosition"  = $Host.UI.RawUI.CursorPosition
	}
	
	$SCRIPT:hostState = New-Object -TypeName PSCustomObject -Property $SCRIPT:hostProperties
}

Function Pop-Host{
	#Restore buffer contents
	$Host.UI.RawUI.BufferSize = $SCRIPT:hostState.BufferSize
	$initPosition = $Host.UI.RawUI.WindowPosition
	$initPosition.x = 0
	$initPosition.y = 0
	$Host.UI.RawUI.SetBufferContents($initPosition, $SCRIPT:hostState.Buffer)
	
	#Start with the window
	$Host.UI.RawUI.WindowTitle    = $SCRIPT:hostState.Title
	$Host.UI.RawUI.WindowPosition = $SCRIPT:hostState.WindowPosition
	$Host.UI.RawUI.WindowSize     = $SCRIPT:hostState.WindowSize
	#Set cursor
	$Host.UI.RawUI.CursorSize     = $SCRIPT:hostState.CursorSize
	$Host.UI.RawUI.CursorPosition = $SCRIPT:hostState.CursorPosition
	#set colors
	$Host.UI.RawUI.ForegroundColor = $SCRIPT:hostState.Foreground
	$Host.UI.RawUI.BackgroundColor = $SCRIPT:hostState.Background
}

Function New-Pixel{
	param(
		[Parameter(Mandatory=$true)][Int]$X,
		[Parameter(Mandatory=$true)][Int]$Y,
		[Parameter(Mandatory=$false)][String]$ForeColor = 'White',
		[Parameter(Mandatory=$false)][String]$BackColor = 'Black',
		[Parameter(Mandatory=$false)][String]$pixel = [Char]9608
	)
	
	$pos = $Host.UI.RawUI.WindowPosition
	$pos.x = $x
	$pos.y = $y
	$row = $Host.UI.RawUI.NewBufferCellArray($pixel, $ForeColor, $BackColor) 
	$Host.UI.RawUI.SetBufferContents($pos,$row) 
}

Function Initialize-GameMatrix{
    param(
    [Int32]$M,
    [Int32]$N
    )
    $gameMatrix = New-Object "Int32[,]" $M, $N
    for($i=0; $i -lt $M; $i++){
        for($j=0; $j -lt $N; $j++){
            $gameMatrix[$i, $j] = 0
        }
    }
    return ,$gameMatrix
}

Function Get-WrappedWidth{
	param(
	    [Int]$x,
	    [Int]$xEdge
	)
	$x += $xEdge;
	while($x -lt 0){
		$x += $SCRIPT:BoardWidth
	}
	while($x -ge $SCRIPT:BoardWidth){
		$x -= $SCRIPT:BoardWidth
	}
	return $x
}

Function Get-WrappedHeight{
	param(
		[Int]$y,
		[Int]$yEdge
	)
	$y += $yEdge
	while($y -lt 0){
		$y += $SCRIPT:BoardHeight
	}
	while($y -ge $SCRIPT:BoardHeight){
		$y -= $SCRIPT:BoardHeight
	}
	return $y
}

Function Get-Neighbours{
	param(
		[Int[,]]$GameMatrix,
		[Int]$coordX,
		[Int]$coordY
	)
	[Int]$nx = 0
	[Int]$ny = 0
	[Int]$count = 0
	for($nx = -1; $nx -le 1; $nx++){
		for($ny = -1; $ny -le 1; $ny++){
			if($nx -or $ny){
				if($GameMatrix[$(Get-WrappedWidth $coordX $nx), $(Get-WrappedHeight $coordY $ny)]){
					$count += 1
				}
			}
		}
	}
	return $count;
}

Function Get-NextGeneration{
	param(
	 [Int[,]]$GameMatrix
	)
	BEGIN{
		$tmpGameMatrix = $GameMatrix;
		Function Get-WrappedWidth{
			param(
			    [Int]$x,
			    [Int]$xEdge
			)
			$x += $xEdge;
			while($x -lt 0){
				$x += $SCRIPT:BoardWidth
			}
			while($x -ge $SCRIPT:BoardWidth){
				$x -= $SCRIPT:BoardWidth
			}
			return $x
		}

		Function Get-WrappedHeight{
			param(
				[Int]$y,
				[Int]$yEdge
			)
			$y += $yEdge;
			while($y -lt 0){
				$y += $SCRIPT:BoardHeight
			}
			while($y -ge $SCRIPT:BoardHeight){
				$y -= $SCRIPT:BoardHeight
			}
			return $y
		}

		Function Get-Neighbours{
			param(
				[Int[,]]$ArrayMatrix,
				[Int]$coordX,
				[Int]$coordY
			)
			[Int]$nx = 0
			[Int]$ny = 0
			[Int]$count = 0
			for($nx = -1; $nx -le 1; $nx++){
				for($ny = -1; $ny -le 1; $ny++){
					if($nx -or $ny){
						if($ArrayMatrix[$(Get-WrappedWidth $coordX $nx), $(Get-WrappedHeight $coordY $ny)]){
							$count += 1
						}
					}
				}
			}
			return $count
		}
		
	}PROCESS{
		
		for($x = 0; $x -lt $SCRIPT:BoardWidth; $x++){
			for($y = 0; $y -lt $SCRIPT:BoardHeight; $y++){
				$neighbors = Get-Neighbours $tmpGameMatrix $x $y
				switch($neighbors){
					{($neighbors -lt 2) -or ($neighbors -gt 3)}
					{$tmpGameMatrix[$x, $y] = 0}
					{($neighbors -eq 3)}
					{$tmpGameMatrix[$x, $y] = 1}
				}
			}
		}
		
	}END{
		$GameMatrix = $tmpGameMatrix
		return ,$GameMatrix
	}
}

Function Set-Board{
	param(
		[Int[,]]$Board
	)
	for($bx = 0; $bx -lt $SCRIPT:BoardWidth; $bx++){
		for($by = 0; $by -lt $SCRIPT:BoardHeight; $by++){
			if($Board[$bx, $by]){
				New-Pixel -X $bx -Y $by -ForeColor "Green" -BackColor "Yellow"
			}else{
				New-Pixel -X $bx -Y $by -ForeColor "Black" -BackColor "Black"
			}
		}
	}
}

Function Main{
    param(
        [int]$cicles
    )

	Push-Host;
	Initialize-Host;
	$gameBoard = Initialize-GameMatrix 50 50;
	#Sample filler
	$gameBoard[25,10] = 1
	$gameBoard[25,11] = 1
	$gameBoard[26,11] = 1
	$gameBoard[27,11] = 1
	$gameBoard[28,9] = 1

    $gameBoard[29,10] = 1
	$gameBoard[29,11] = 1
	$gameBoard[20,11] = 1
	$gameBoard[21,11] = 1
	$gameBoard[22,9] = 1
	Set-Board $gameBoard
	for($itr = 0; $itr -lt $cicles; $itr++){
		$newBoard = Get-NextGeneration $gameBoard
		Set-Board $newBoard
	}
	Pop-Host
}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$SCRIPT:hostProperties = @{}
$SCRIPT:hostState = $null
$SCRIPT:BoardWidth = 50
$SCRIPT:BoardHeight = 50

. Main -cicles 35