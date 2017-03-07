@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION

:: Set the global vars
SET WIDTH=0
SET HEIGHT=0
SET DENSITY=0
SET CELLCOUNT=0
SET GENERATION=0
SET ALIVECOUNT=0

:: Now check the command line params
IF "%1"=="" (
	GOTO HELP
)

IF NOT "%3"=="" (
	CALL :RANDOM %1 %2 %3 
) ELSE (
	IF EXIST "%1" (
		CALL :LOAD %1
	) ELSE (
		ECHO File %1 not found.
		GOTO EOF
	)
)

:: Calculate the number of cells in grid and then kick of the process loop
SET /A CELLCOUNT=%WIDTH%*%HEIGHT%
GOTO PROCESS

::::::::::::::::::::
:: Generate a random grid 'A'. This grid holds the cell layout for display
:: Also for safety, delete any grid 'B' cells that might be in memory
:: Grid 'B' used to store temporary cell values before they are assigned to grid 'A' 
:RANDOM
SET WIDTH=%1
SET HEIGHT=%2
SET DENSITY=%3

FOR /L %%h IN (1, 1, %HEIGHT%) DO (
	FOR /L %%w IN (1, 1, %WIDTH%) DO (
					
		SET /A RAND=!RANDOM!*100/32768

		IF !DENSITY! GEQ !RAND! (
			SET A[%%w][%%h]=@
			SET /A ALIVECOUNT=!ALIVECOUNT!+1
		) ELSE (
			SET "A[%%w][%%h]= "
		)
		
		SET B[%%w][%%h]=
	)	
)
GOTO EOF


::::::::::::::::::::::::::::::::::
:: Load file specified in %1 and load into grid 'A'
:: 
:LOAD
FOR /F "delims=" %%a IN (%1) DO (
	SET /A HEIGHT=!HEIGHT!+1
	SET LINE=%%a
	CALL :GET_LINE_LENGTH "!LINE!"	
	SET /A LASTINDEX=!LINELENGTH!-1
	
	IF !LINELENGTH! GTR !WIDTH! (
		SET WIDTH=!LINELENGTH!
	)

	REM Now build the alive values of grid 'A' into memory
	FOR /L %%c in (0, 1, !LASTINDEX!) do (
		SET "CHAR=!LINE:~%%c,1!"
		SET /A INDEX=%%c+1
		IF "!CHAR!"=="@" (
			SET A[!INDEX!][!HEIGHT!]=!CHAR!
			SET /A ALIVECOUNT=!ALIVECOUNT!+1
		)
	)
				
) 

:: Now build the empty values of grid 'A' into memory
FOR /L %%h IN (1, 1, %HEIGHT%) DO (
	FOR /L %%w IN (1, 1, %WIDTH%) DO (
					
		IF NOT DEFINED A[%%w][%%h] (
			SET "A[%%w][%%h]= "
		)

		SET B[%%w][%%h]=
	)	
)
GOTO EOF



:GET_LINE_LENGTH
SET "THISLINE=%1"
SET LINELENGTH=0
:LINECOUNTERLOOP
IF DEFINED THISLINE (
    rem shorten string by one character
    SET THISLINE=%THISLINE:~1%
    rem increment the string count variable %LINELENGTH%
    SET /A LINELENGTH=!LINELENGTH!+1
    rem repeat until string is null
    GOTO LINECOUNTERLOOP
)
GOTO EOF



::::::::::::::::::::::::::::::
:: TOP OF MAIN PROCESSING LOOP
::
:: Display grid 'A'
:: Loop through all the Grid 'A' cells:
:: 	- Get values neighbouring cells
::	- Get count of alive neighbours 
::	- Apply 'Game of Life' rules and store resulting value in grid 'b' cell
:: Assign grid 'b' cell values to grid 'a' cell values
:: Loop back to start process again
:PROCESS
SET /A GENERATION=%GENERATION%+1
CLS
ECHO Conway's Game of Life. 
ECHO Generation: %GENERATION%
ECHO Live Cells: %ALIVECOUNT%/%CELLCOUNT%
CALL :DISPLAY

IF "%ALIVECOUNT%"=="0" (GOTO EOF)

SET ALIVECOUNT=0
SET COUNTER=0
FOR /L %%h IN (1, 1, %HEIGHT%) DO (
	FOR /L %%w IN (1, 1, %WIDTH%) DO (
		
		SET /A COUNTER=!COUNTER!+1
		TITLE Calculating Cell !COUNTER!/%CELLCOUNT%
			
		SET X=0
		SET Y=0
		SET NCOUNT=0
		
		REM Find the 3 cells above this cell
		IF %%h EQU 1 (SET Y=%HEIGHT%) ELSE (SET /A Y=%%h-1)
		IF %%w EQU 1 (SET X=%WIDTH%) ELSE (SET /A X=%%w-1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))	
		SET X=%%w
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))
		IF %%w EQU %WIDTH% (SET X=1) ELSE (SET /A X=%%w+1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))
		
		REM Find the 2 cells left and right of this cell
		SET Y=%%h
		IF %%w EQU 1 (SET X=%WIDTH%) ELSE (SET /A X=%%w-1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))
		IF %%w EQU %WIDTH% (SET X=1) ELSE (SET /A X=%%w+1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))

		REM Find the 3 cells below this cell
		IF %%h EQU %HEIGHT% (SET Y=1) ELSE (SET /A Y=%%h+1)
		IF %%w EQU 1 (SET X=%WIDTH%) ELSE (SET /A X=%%w-1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))
		SET X=%%w
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))
		IF %%w EQU %WIDTH% (SET X=1) ELSE (SET /A X=%%w+1)
		FOR /F "tokens=1,2" %%a IN ("!X! !Y!") DO (IF "!A[%%a][%%b]!"=="@" (SET /A NCOUNT=!NCOUNT!+1))	

		REM Check if this cell is alive or not
		IF "!A[%%w][%%h]!"=="@" (
			SET ALIVE=Y
			SET /A ALIVECOUNT=!ALIVECOUNT!+1
		) ELSE (
			SET ALIVE=N
		)
				
		REM Assign live status to grid 'B' based on rules
		IF "!ALIVE!"=="Y" (
			IF !NCOUNT! LSS 2 (
				SET "B[%%w][%%h]= "
			)
			IF !NCOUNT! EQU 2 (
				SET B[%%w][%%h]=@
			)
			IF !NCOUNT! EQU 3 (
				SET B[%%w][%%h]=@
			)
			IF !NCOUNT! GTR 3 (
				SET "B[%%w][%%h]= "
			)
		)
		
		REM Assign dead status to grid 'B' based on rules
		IF "!ALIVE!"=="N" (
			IF !NCOUNT! EQU 3 (
				SET B[%%w][%%h]=@
			)
		)	
	)	
)

:: Now check if we have set any Grid 'B' cells 
:: If so, assign these cell values to Grid 'A' cells
FOR /L %%h IN (1, 1, %HEIGHT%) DO (
		FOR /L %%w IN (1, 1, %WIDTH%) DO (
			
			IF DEFINED B[%%w][%%h] (
				IF "!B[%%w][%%h]!"==" " (
					SET "A[%%w][%%h]= "
				)
				IF "!B[%%w][%%h]!"=="@" (
					SET A[%%w][%%h]=@
				)
			)		
		)	
)

:: Loop back to the top of process to start again
GOTO PROCESS


::::::::::::::::::::::::::::::::::::::::::::
:: THIS FUNCTION DISPLAYS GRID 'A' ON SCREEN 
::::::::::::::::::::::::::::::::::::::::::::
:DISPLAY
SET TOP=
SET BOT=
FOR /L %%h IN (1, 1, %height%) DO (

	IF %%h EQU 1 (FOR /L %%w IN (1, 1, %width%) DO (SET TOP=_!TOP!))
	IF %%h EQU 1 ECHO .!TOP!.
	
	SET ROW=
	FOR /L %%w IN (1, 1, %WIDTH%) DO (
			SET ROW=!ROW!!A[%%w][%%h]!
	)
	
	ECHO ^|!ROW!^|
		
	IF %%h EQU %height% (FOR /L %%w IN (1, 1, %width%) DO (SET BOT=~!BOT!))
	IF %%h EQU %height% ECHO `!BOT!'	
)
GOTO EOF

:HELP
ECHO/
ECHO 'Conway's Game of Life' - Batch Edition - Chazjn 0.2 06/03/2017
ECHO ===============================================================
ECHO Usage is as follows:
ECHO 	life [width] [height] [%%density]
ECHO 	life [input file]
ECHO E.g.
ECHO 	life 15 10 25
ECHO 	life gliders.txt
ECHO/
ECHO For more infomation visit: https://en.wikipedia.org/wiki/Conway's_Game_of_Life
ECHO 							https://github.com/chazjn/batch-gof
GOTO EOF

:EOF