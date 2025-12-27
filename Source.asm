INCLUDE Irvine32.inc

.data
    ; Game constants
    SCREEN_WIDTH = 80
    SCREEN_HEIGHT = 25
    MAX_BULLETS = 10
    MAX_ENEMIES = 15
    MAX_ENEMY_BULLETS = 20
    MAX_NAME_LENGTH = 20

    ; Game state variables
    gameRunning BYTE 1
    currentLevel BYTE 1
    playerX BYTE 40
    playerY BYTE 22
    score DWORD 0
    lives BYTE 3
    enemiesKilled BYTE 0
    levelTargets BYTE 5, 10, 15    ; Enemies to kill per level
    gamePaused BYTE 0
    gameInitialized BYTE 0

    ; Player name
    playerName BYTE MAX_NAME_LENGTH DUP(0)
    namePrompt BYTE "Enter your name (max 19 chars): ", 0
    
    ; Bullet arrays
    bulletX BYTE MAX_BULLETS DUP(255)
    bulletY BYTE MAX_BULLETS DUP(255)
    bulletActive BYTE MAX_BULLETS DUP(0)
    
    ; Enemy arrays
    enemyX BYTE MAX_ENEMIES DUP(255)
    enemyY BYTE MAX_ENEMIES DUP(255)
    enemyActive BYTE MAX_ENEMIES DUP(0)
    enemyDirection BYTE MAX_ENEMIES DUP(1)  ; 1=right, -1=left
    
    ; Enemy bullet arrays
    enemyBulletX BYTE MAX_ENEMY_BULLETS DUP(255)
    enemyBulletY BYTE MAX_ENEMY_BULLETS DUP(255)
    enemyBulletActive BYTE MAX_ENEMY_BULLETS DUP(0)
    
    ; Game timing and counters
    gameSpeed DWORD 50
    enemyMoveCounter BYTE 0
    enemyShootCounter BYTE 0
    enemySpawnCounter BYTE 0
    frameCounter DWORD 0
    enemySideMoveCounter BYTE 0
    
    ; Screen buffer for flicker-free drawing
    prevPlayerX BYTE 255
    prevPlayerY BYTE 255
    
    ; Messages
    welcomeTitle BYTE "====== SPACE SHIP BATTLE GAME ======", 0
    menuOptions BYTE "1. Start Game", 13, 10, "2. Instructions", 13, 10, "3. Exit", 13, 10, "Choice: ", 0
    instructionsText BYTE "INSTRUCTIONS:", 13, 10
                    BYTE "- Use LEFT/RIGHT arrow keys to move", 13, 10
                    BYTE "- Press SPACEBAR to shoot", 13, 10
                    BYTE "- Press P to pause/unpause", 13, 10
                    BYTE "- Press ESC to exit", 13, 10
                    BYTE "- Avoid enemy ships and bullets!", 13, 10
                    BYTE "- Level 1: Kill 5 enemies", 13, 10
                    BYTE "- Level 2: Kill 10 enemies", 13, 10
                    BYTE "- Level 3: Kill 15 enemies", 13, 10, 10
                    BYTE "Press any key to return...", 0
    
    gameOverMsg BYTE "GAME OVER!", 0
    gameWonMsg BYTE "CONGRATULATIONS! YOU WON!", 0
    finalScoreMsg BYTE "Final Score: ", 0
    levelMsg BYTE "Level: ", 0
    scoreMsg BYTE "Score: ", 0
    livesMsg BYTE "Lives: ", 0
    enemiesMsg BYTE "Enemies: ", 0
    pausedMsg BYTE "PAUSED - Press P to continue", 0
    
    ; File handling
    filename BYTE "highscores.txt", 0
    fileHandle DWORD ?
    bytesWritten DWORD ?
    scoreBuffer BYTE 20 DUP(0)  ; Buffer for score string conversion
    separatorMsg BYTE " - Score: ", 0
    newlineChars BYTE 13, 10, 0
    
    ; Symbols
    playerShip BYTE "^", 0
    enemyShip BYTE "V", 0
    bulletChar BYTE "|", 0
    spaceChar BYTE " ", 0
    
.code

;==================================================
; Main Procedure
;==================================================
main PROC
    call Clrscr
    call ShowWelcome
    call ShowMenu
    
    ; Game loop
    MainGameLoop:
        cmp gameRunning, 0
        je ExitGame
        
        call ProcessInput
        cmp gameRunning, 0
        je ExitGame
        
        cmp gamePaused, 0
        jne SkipGameLogic
        
        call UpdateGame
        call DrawGame
        
    SkipGameLogic:
        mov eax, gameSpeed
        call Delay
        inc frameCounter
        jmp MainGameLoop
    
    ExitGame:
        call SaveHighScore
        call ShowGameEnd
        call WaitMsg
        exit

main ENDP

;==================================================
; Show Welcome Screen
;==================================================
ShowWelcome PROC
    call Clrscr
    mov dh, 5
    mov dl, 20
    call Gotoxy
    
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET welcomeTitle
    call WriteString
    
    mov dh, 8
    mov dl, 10
    call Gotoxy
    
    mov eax, white
    call SetTextColor
    mov edx, OFFSET namePrompt
    call WriteString
    
    mov edx, OFFSET playerName
    mov ecx, MAX_NAME_LENGTH - 1
    call ReadString
    
    ret
ShowWelcome ENDP

;==================================================
; Show Main Menu
;==================================================
ShowMenu PROC
    MenuLoop:
        call Clrscr
        mov dh, 5
        mov dl, 25
        call Gotoxy
        
        mov eax, cyan
        call SetTextColor
        mov edx, OFFSET welcomeTitle
        call WriteString
        
        mov dh, 10
        mov dl, 25
        call Gotoxy
        
        mov eax, white
        call SetTextColor
        mov edx, OFFSET menuOptions
        call WriteString
        
        call ReadChar
        cmp al, '1'
        je StartGame
        cmp al, '2'
        je ShowInstructions
        cmp al, '3'
        je ExitMenu
        jmp MenuLoop
    
    StartGame:
        call InitializeGame
        ret
    
    ShowInstructions:
        call ShowInstructionsScreen
        jmp MenuLoop
    
    ExitMenu:
        mov gameRunning, 0
        ret
ShowMenu ENDP

;==================================================
; Show Instructions
;==================================================
ShowInstructionsScreen PROC
    call Clrscr
    mov dh, 2
    mov dl, 5
    call Gotoxy
    
    mov eax, yellow
    call SetTextColor
    mov edx, OFFSET instructionsText
    call WriteString
    
    call ReadChar
    ret
ShowInstructionsScreen ENDP

;==================================================
; Initialize Game
;==================================================
InitializeGame PROC
    ; Reset game variables
    mov currentLevel, 1
    mov score, 0
    mov lives, 3
    mov enemiesKilled, 0
    mov playerX, 40
    mov playerY, 22
    mov gameSpeed, 50
    mov frameCounter, 0
    mov enemyMoveCounter, 0
    mov enemyShootCounter, 0
    mov enemySpawnCounter, 0
    mov enemySideMoveCounter, 0
    mov gameInitialized, 0
    mov prevPlayerX, 255
    mov prevPlayerY, 255
    
    ; Clear all arrays
    call ClearAllArrays
    
    ; Spawn initial enemies
    call SpawnInitialEnemies
    
    ret
InitializeGame ENDP

;==================================================
; Clear All Arrays - Helper procedure
;==================================================
ClearAllArrays PROC
    mov ecx, MAX_BULLETS
    mov esi, 0
    ClearBullets:
        mov bulletActive[esi], 0
        mov bulletX[esi], 255
        mov bulletY[esi], 255
        inc esi
        loop ClearBullets
    
    mov ecx, MAX_ENEMIES
    mov esi, 0
    ClearEnemies:
        mov enemyActive[esi], 0
        mov enemyX[esi], 255
        mov enemyY[esi], 255
        mov enemyDirection[esi], 1
        inc esi
        loop ClearEnemies
    
    mov ecx, MAX_ENEMY_BULLETS
    mov esi, 0
    ClearEnemyBullets:
        mov enemyBulletActive[esi], 0
        mov enemyBulletX[esi], 255
        mov enemyBulletY[esi], 255
        inc esi
        loop ClearEnemyBullets
    
    ret
ClearAllArrays ENDP

;==================================================
; Spawn Initial Enemies
;==================================================
SpawnInitialEnemies PROC
    mov ecx, 3  ; Start with 3 enemies
    mov esi, 0
    mov bl, 10  ; Starting X position
    
    SpawnLoop:
        cmp esi, MAX_ENEMIES
        jge DoneSpawning
        
        mov enemyActive[esi], 1
        mov enemyX[esi], bl
        mov enemyY[esi], 2
        mov enemyDirection[esi], 1
        
        add bl, 25  ; Space enemies apart
        cmp bl, 70
        jle ContinueSpawn
        mov bl, 10  ; Reset to left side
        
        ContinueSpawn:
            inc esi
            loop SpawnLoop
    
    DoneSpawning:
        ret
SpawnInitialEnemies ENDP

;==================================================
; Process Input
;==================================================
ProcessInput PROC
    call ReadKey
    jz NoKeyPressed
    
    cmp ah, 1       ; ESC key
    je ExitGameInput
    
    cmp al, 'p'     ; Pause key
    je TogglePause
    cmp al, 'P'
    je TogglePause
    
    cmp gamePaused, 0
    jne NoKeyPressed
    
    cmp ah, 75      ; Left arrow
    je MoveLeft
    cmp ah, 77      ; Right arrow
    je MoveRight
    cmp al, 32      ; Spacebar
    je FireBullet
    
    jmp NoKeyPressed
    
    ExitGameInput:
        mov gameRunning, 0
        jmp NoKeyPressed
    
    TogglePause:
        xor gamePaused, 1
        jmp NoKeyPressed
    
    MoveLeft:
        cmp playerX, 1
        jle NoKeyPressed
        dec playerX
        jmp NoKeyPressed
    
    MoveRight:
        cmp playerX, 78
        jge NoKeyPressed
        inc playerX
        jmp NoKeyPressed
    
    FireBullet:
        call CreatePlayerBullet
    
    NoKeyPressed:
        ret
ProcessInput ENDP

;==================================================
; Create Player Bullet
;==================================================
CreatePlayerBullet PROC
    mov ecx, MAX_BULLETS
    mov esi, 0
    
    FindEmptyBullet:
        cmp bulletActive[esi], 0
        je CreateBullet
        inc esi
        loop FindEmptyBullet
        ret     ; No empty slot found
    
    CreateBullet:
        mov bulletActive[esi], 1
        mov al, playerX
        mov bulletX[esi], al
        mov al, playerY
        dec al
        mov bulletY[esi], al
    
    ret
CreatePlayerBullet ENDP

;==================================================
; Update Game Logic
;==================================================
UpdateGame PROC
    call UpdateBullets
    call UpdateEnemies
    call UpdateEnemyBullets
    call CheckCollisions
    call SpawnEnemies
    call CheckLevelComplete
    ret
UpdateGame ENDP

;==================================================
; Update Bullets
;==================================================
UpdateBullets PROC
    mov ecx, MAX_BULLETS
    mov esi, 0
    
    UpdateBulletLoop:
        cmp bulletActive[esi], 0
        je NextBullet
        
        ; Move bullet up
        dec bulletY[esi]
        
        ; Check if bullet is off screen
        cmp bulletY[esi], 0
        jge NextBullet
        
        ; Deactivate bullet
        mov bulletActive[esi], 0
        mov bulletX[esi], 255
        mov bulletY[esi], 255
        
        NextBullet:
            inc esi
            loop UpdateBulletLoop
    
    ret
UpdateBullets ENDP

;==================================================
; Update Enemies
;==================================================
UpdateEnemies PROC
    call UpdateEnemyMovement
    call UpdateEnemyShooting
    ret
UpdateEnemies ENDP

;==================================================
; Update Enemy Movement - Helper procedure
;==================================================
UpdateEnemyMovement PROC
    inc enemyMoveCounter
    mov al, 5  ; Base movement speed
    cmp currentLevel, 2
    jl CheckMoveSpeed
    mov al, 4   ; Faster for level 2
    cmp currentLevel, 3
    jl CheckMoveSpeed
    mov al, 3   ; Fastest for level 3
    
    CheckMoveSpeed:
        cmp enemyMoveCounter, al
        jl SkipEnemyMove
    
    mov enemyMoveCounter, 0
    
    ; Side movement counter for levels 2 and 3
    cmp currentLevel, 2
    jl NoSideMoveCount
    inc enemySideMoveCounter
    
    NoSideMoveCount:
        mov ecx, MAX_ENEMIES
        mov esi, 0
    
    UpdateEnemyLoop:
        cmp enemyActive[esi], 0
        je NextEnemy
        
        ; Move enemy down
        inc enemyY[esi]
        
        ; Level-specific side movement
        call ProcessEnemySideMovement
        
        ; Check if enemy reached bottom
        cmp enemyY[esi], 24
        jle NextEnemy
        
        ; Enemy off screen
        mov enemyActive[esi], 0
        mov enemyX[esi], 255
        mov enemyY[esi], 255
        
        NextEnemy:
            inc esi
            loop UpdateEnemyLoop
    
    SkipEnemyMove:
        ret
UpdateEnemyMovement ENDP

;==================================================
; Process Enemy Side Movement - Helper procedure
;==================================================
ProcessEnemySideMovement PROC
    cmp currentLevel, 1
    je NoSideMove  ; Level 1: only downward movement
    
    ; Level 2 and 3: side movement every 2nd downward move
    mov al, enemySideMoveCounter
    and al, 1  ; Check if odd frame
    cmp al, 0
    je NoSideMove
    
    ; Side movement
    mov al, enemyDirection[esi]
    add enemyX[esi], al
    
    ; Check boundaries and reverse direction
    cmp enemyX[esi], 3
    jl ReverseDirection
    cmp enemyX[esi], 76
    jle CheckRandomDirection
    
    ReverseDirection:
        neg enemyDirection[esi]
        jmp CheckRandomDirection
    
    CheckRandomDirection:
        ; Level 3: Random direction changes
        cmp currentLevel, 3
        jl NoSideMove
        
        ; 10% chance to randomly change direction
        mov eax, 20
        call RandomRange
        cmp eax, 0
        jne NoSideMove
        
        ; Randomly reverse direction
        neg enemyDirection[esi]
    
    NoSideMove:
        ret
ProcessEnemySideMovement ENDP

;==================================================
; Update Enemy Shooting - Helper procedure
;==================================================
UpdateEnemyShooting PROC
    cmp currentLevel, 2
    jl NoEnemyShooting
    
    inc enemyShootCounter
    mov al, 35   ; Level 2 shooting frequency
    cmp currentLevel, 3
    jl CheckShootRate
    mov al, 25   ; Level 3 faster shooting
    
    CheckShootRate:
        cmp enemyShootCounter, al
        jl NoEnemyShooting
    
    mov enemyShootCounter, 0
    call CreateEnemyBullet

    NoEnemyShooting:
        ret
UpdateEnemyShooting ENDP

;==================================================
; Create Enemy Bullet
;==================================================
CreateEnemyBullet PROC
    ; Find active enemy to shoot from
    mov ecx, MAX_ENEMIES
    mov esi, 0
    
    FindShootingEnemy:
        cmp enemyActive[esi], 0
        je NextShootingEnemy
        
        ; Higher chance to shoot for more action
        mov eax, 8
        cmp currentLevel, 3
        jl Level2Shoot
        mov eax, 6  ; Even higher chance for level 3
        
        Level2Shoot:
            call RandomRange
            cmp eax, 0
            jne NextShootingEnemy
        
        ; Find empty bullet slot
        push esi
        call FindEmptyEnemyBulletSlot
        pop esi
        cmp eax, -1
        je NextShootingEnemy
        
        ; Create bullet at found slot
        mov edi, eax
        mov enemyBulletActive[edi], 1
        mov al, enemyX[esi]
        mov enemyBulletX[edi], al
        mov al, enemyY[esi]
        inc al
        mov enemyBulletY[edi], al
        ret
        
        NextShootingEnemy:
            inc esi
            loop FindShootingEnemy
    
    ret
CreateEnemyBullet ENDP

;==================================================
; Find Empty Enemy Bullet Slot - Helper procedure
;==================================================
FindEmptyEnemyBulletSlot PROC
    mov ecx, MAX_ENEMY_BULLETS
    mov edi, 0
    
    FindSlot:
        cmp enemyBulletActive[edi], 0
        je FoundSlot
        inc edi
        loop FindSlot
        
    ; No slot found
    mov eax, -1
    ret
    
    FoundSlot:
        mov eax, edi
        ret
FindEmptyEnemyBulletSlot ENDP

;==================================================
; Update Enemy Bullets
;==================================================
UpdateEnemyBullets PROC
    mov ecx, MAX_ENEMY_BULLETS
    mov esi, 0
    
    UpdateEnemyBulletLoop:
        cmp enemyBulletActive[esi], 0
        je NextEnemyBullet
        
        ; Move bullet down
        inc enemyBulletY[esi]
        
        ; Check if bullet is off screen
        cmp enemyBulletY[esi], 25
        jle NextEnemyBullet
        
        ; Deactivate bullet
        mov enemyBulletActive[esi], 0
        
        NextEnemyBullet:
            inc esi
            loop UpdateEnemyBulletLoop
    
    ret
UpdateEnemyBullets ENDP

;==================================================
; Check Collisions - FIXED VERSION
;==================================================
CheckCollisions PROC
    call CheckBulletEnemyCollisions
    call CheckEnemyBulletPlayerCollisions
    call CheckEnemyPlayerCollisions
    ret
CheckCollisions ENDP

;==================================================
; Check Bullet-Enemy Collisions - Helper procedure
;==================================================
CheckBulletEnemyCollisions PROC
    mov ecx, MAX_BULLETS
    mov esi, 0
    
    CheckBulletLoop:
        cmp bulletActive[esi], 0
        je NextBullet
        
        ; Check this bullet against all enemies
        push esi
        push ecx
        call CheckBulletAgainstEnemies
        pop ecx
        pop esi
        
        NextBullet:
            inc esi
            loop CheckBulletLoop
    
    ret
CheckBulletEnemyCollisions ENDP

;==================================================
; Check Bullet Against Enemies - Helper procedure
;==================================================
CheckBulletAgainstEnemies PROC
    mov ecx, MAX_ENEMIES
    mov edi, 0
    
    CheckEnemyLoop:
        cmp enemyActive[edi], 0
        je NextEnemy
        
        ; Check collision
        mov al, bulletX[esi]
        cmp al, enemyX[edi]
        jne NextEnemy
        
        mov al, bulletY[esi]
        cmp al, enemyY[edi]
        jne NextEnemy
        
        ; COLLISION DETECTED!
        call ProcessBulletEnemyCollision
        ret  ; Exit after collision
        
        NextEnemy:
            inc edi
            loop CheckEnemyLoop
    
    ret
CheckBulletAgainstEnemies ENDP

;==================================================
; Process Bullet-Enemy Collision - Helper procedure
;==================================================
ProcessBulletEnemyCollision PROC
    ; Deactivate both objects
    mov bulletActive[esi], 0
    mov enemyActive[edi], 0
    
    ; Clear positions
    mov bulletX[esi], 255
    mov bulletY[esi], 255
    mov enemyX[edi], 255
    mov enemyY[edi], 255
    
    ; Update score and enemies killed
    add score, 100
    inc enemiesKilled
    
    ; Clear screen immediately
    push eax
    push edx
    
    mov dh, enemyY[edi]
    cmp dh, 255
    je SkipClear
    
    mov dl, enemyX[edi]
    cmp dl, 255
    je SkipClear
    
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    SkipClear:
        pop edx
        pop eax
    
    ret
ProcessBulletEnemyCollision ENDP

;==================================================
; Check Enemy Bullet-Player Collisions - Helper procedure
;==================================================
CheckEnemyBulletPlayerCollisions PROC
    mov ecx, MAX_ENEMY_BULLETS
    mov esi, 0
    
    CheckEnemyBulletLoop:
        cmp enemyBulletActive[esi], 0
        je NextEnemyBullet
        
        mov al, enemyBulletX[esi]
        cmp al, playerX
        jne NextEnemyBullet
        
        mov al, enemyBulletY[esi]
        cmp al, playerY
        jne NextEnemyBullet
        
        ; Player hit by enemy bullet!
        mov enemyBulletActive[esi], 0
        mov enemyBulletX[esi], 255
        mov enemyBulletY[esi], 255
        dec lives
        
        NextEnemyBullet:
            inc esi
            loop CheckEnemyBulletLoop
    
    ret
CheckEnemyBulletPlayerCollisions ENDP

;==================================================
; Check Enemy-Player Collisions - Helper procedure
;==================================================
CheckEnemyPlayerCollisions PROC
    mov ecx, MAX_ENEMIES
    mov esi, 0
    
    CheckEnemyPlayerLoop:
        cmp enemyActive[esi], 0
        je NextEnemyPlayer
        
        mov al, enemyX[esi]
        cmp al, playerX
        jne NextEnemyPlayer
        
        mov al, enemyY[esi]
        cmp al, playerY
        jne NextEnemyPlayer
        
        ; Direct collision with enemy ship!
        mov enemyActive[esi], 0
        mov enemyX[esi], 255
        mov enemyY[esi], 255
        dec lives
        
        NextEnemyPlayer:
            inc esi
            loop CheckEnemyPlayerLoop
    
    ret
CheckEnemyPlayerCollisions ENDP

;==================================================
; Spawn Enemies
;==================================================
SpawnEnemies PROC
    inc enemySpawnCounter
    
    ; Calculate spawn rate based on level
    mov al, 30
    cmp currentLevel, 2
    jl CheckSpawnRate
    mov al, 25
    cmp currentLevel, 3
    jl CheckSpawnRate
    mov al, 20    ; Level 3 spawn rate
    
    CheckSpawnRate:
        cmp enemySpawnCounter, al
        jl NoSpawn
    
    mov enemySpawnCounter, 0
    
    ; Find empty enemy slot
    call FindEmptyEnemySlot
    cmp eax, -1
    je NoSpawn
    
    ; Spawn enemy at found slot
    mov esi, eax
    mov enemyActive[esi], 1
    
    ; Random X position
    mov eax, 70
    call RandomRange
    add al, 5
    mov enemyX[esi], al
    
    mov enemyY[esi], 2
    
    ; Set direction based on level
    call SetEnemyDirection
    
    NoSpawn:
        ret
SpawnEnemies ENDP

;==================================================
; Find Empty Enemy Slot - Helper procedure
;==================================================
FindEmptyEnemySlot PROC
    mov ecx, MAX_ENEMIES
    mov esi, 0
    
    FindSlot:
        cmp enemyActive[esi], 0
        je FoundSlot
        inc esi
        loop FindSlot
        
    ; No slot found
    mov eax, -1
    ret
    
    FoundSlot:
        mov eax, esi
        ret
FindEmptyEnemySlot ENDP

;==================================================
; Set Enemy Direction - Helper procedure
;==================================================
SetEnemyDirection PROC
    cmp currentLevel, 1
    je SetLevel1Direction
    
    ; Level 2 and 3: Random initial direction
    mov eax, 2
    call RandomRange
    cmp eax, 0
    je LeftDirection
    mov enemyDirection[esi], 1
    ret
    
    LeftDirection:
        mov enemyDirection[esi], -1
        ret
    
    SetLevel1Direction:
        mov enemyDirection[esi], 1
        ret
SetEnemyDirection ENDP

;==================================================
; Check Level Complete
;==================================================
CheckLevelComplete PROC
    mov al, currentLevel
    dec al
    movzx ebx, al
    mov al, levelTargets[ebx]
    
    cmp enemiesKilled, al
    jl CheckPlayerDead
    
    ; Level complete
    inc currentLevel
    cmp currentLevel, 4
    jle ContinueToNextLevel
    
    ; Game won
    mov gameRunning, 0
    ret
    
    ContinueToNextLevel:
        ; Reset for next level
        mov enemiesKilled, 0
        
        ; Increase difficulty
        cmp gameSpeed, 30
        jle SkipSpeedIncrease
        sub gameSpeed, 15
        
        SkipSpeedIncrease:
            ; Spawn some enemies for next level
            call SpawnInitialEnemies
            ret
    
    CheckPlayerDead:
        ; Check if player is dead
        cmp lives, 0
        jg StillAlive
        mov gameRunning, 0
    
    StillAlive:
        ret
CheckLevelComplete ENDP

;==================================================
; Draw Game Screen (Flicker-free)
;==================================================
DrawGame PROC
    ; Only clear screen on first draw
    cmp gameInitialized, 0
    jne SkipInitialClear
    
    call Clrscr
    mov gameInitialized, 1
    
    SkipInitialClear:
        ; Always draw UI (it updates)
        call DrawUI
        
        cmp gamePaused, 1
        je DrawPauseMessage
        
        ; Clear previous player position
        call ClearPreviousPlayerPosition
        
        ; Draw all game objects
        call DrawPlayer
        call DrawBullets
        call DrawEnemies
        call DrawEnemyBullets
        
        ; Update previous player position
        mov al, playerX
        mov prevPlayerX, al
        mov al, playerY
        mov prevPlayerY, al
        
        ret
    
    DrawPauseMessage:
        mov dh, 12
        mov dl, 25
        call Gotoxy
        mov eax, yellow
        call SetTextColor
        mov edx, OFFSET pausedMsg
        call WriteString
        ret
DrawGame ENDP

;==================================================
; Clear Previous Player Position - Helper procedure
;==================================================
ClearPreviousPlayerPosition PROC
    cmp prevPlayerX, 255
    je SkipPlayerClear
    
    mov dh, prevPlayerY
    mov dl, prevPlayerX
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    SkipPlayerClear:
        ret
ClearPreviousPlayerPosition ENDP

;==================================================
; Draw UI
;==================================================
DrawUI PROC
    ; Draw level
    mov dh, 0
    mov dl, 2
    call Gotoxy
    mov eax, cyan
    call SetTextColor
    mov edx, OFFSET levelMsg
    call WriteString
    movzx eax, currentLevel
    call WriteDec
    
    ; Draw score
    mov dh, 0
    mov dl, 15
    call Gotoxy
    mov edx, OFFSET scoreMsg
    call WriteString
    mov eax, score
    call WriteDec
    
    ; Draw lives
    mov dh, 0
    mov dl, 35
    call Gotoxy
    mov edx, OFFSET livesMsg
    call WriteString
    movzx eax, lives
    call WriteDec
    
    ; Draw enemies killed
    mov dh, 0
    mov dl, 50
    call Gotoxy
    mov edx, OFFSET enemiesMsg
    call WriteString
    movzx eax, enemiesKilled
    call WriteDec
    mov al, '/'
    call WriteChar
    mov al, currentLevel
    dec al
    movzx ebx, al
    movzx eax, levelTargets[ebx]
    call WriteDec
    
    ret
DrawUI ENDP

;==================================================
; Draw Player
;==================================================
DrawPlayer PROC
    mov dh, playerY
    mov dl, playerX
    call Gotoxy
    
    mov eax, green
    call SetTextColor
    mov al, '^'
    call WriteChar
    
    ret
DrawPlayer ENDP

;==================================================
; Draw Bullets
;==================================================
DrawBullets PROC
    mov ecx, MAX_BULLETS
    mov esi, 0
    
    DrawBulletLoop:
        call DrawSingleBullet
        inc esi
        loop DrawBulletLoop
    
    ret
DrawBullets ENDP

;==================================================
; Draw Single Bullet - Helper procedure
;==================================================
DrawSingleBullet PROC
    cmp bulletActive[esi], 0
    je ClearBulletPosition
    
    ; Clear previous position (bullet moved up one)
    mov dh, bulletY[esi]
    inc dh
    cmp dh, 25
    jge SkipBulletClear
    
    mov dl, bulletX[esi]
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    SkipBulletClear:
        ; Only draw if bullet is on visible screen
        mov dh, bulletY[esi]
        cmp dh, 23
        jg ExitDrawBullet
        cmp dh, 2
        jl ExitDrawBullet
        
        ; Draw current position
        mov dl, bulletX[esi]
        call Gotoxy
        
        mov eax, yellow
        call SetTextColor
        mov al, '|'
        call WriteChar
        jmp ExitDrawBullet
    
    ClearBulletPosition:
        ; Bullet was destroyed, clear its last position
        mov dh, bulletY[esi]
        cmp dh, 25
        jg ResetBulletPos
        cmp dh, 0
        jl ResetBulletPos
        
        mov dl, bulletX[esi]
        cmp dl, 80
        jge ResetBulletPos
        cmp dl, 0
        jl ResetBulletPos
        
        call Gotoxy
        mov al, ' '
        call WriteChar
        
        ResetBulletPos:
            ; Reset position to prevent future clearing attempts
            mov bulletX[esi], 255
            mov bulletY[esi], 255
    
    ExitDrawBullet:
        ret
DrawSingleBullet ENDP

;==================================================
; Draw Enemies
;==================================================
DrawEnemies PROC
    mov ecx, MAX_ENEMIES
    mov esi, 0
    
    DrawEnemyLoop:
        call DrawSingleEnemy
        inc esi
        loop DrawEnemyLoop
    
    ret
DrawEnemies ENDP

;==================================================
; Draw Single Enemy - Helper procedure
;==================================================
DrawSingleEnemy PROC
    cmp enemyActive[esi], 0
    je ClearEnemyPosition
    
    ; Clear previous position (enemy moved down/side)
    mov dh, enemyY[esi]
    cmp dh, 2
    jle SkipEnemyClearY
    dec dh
    
    mov dl, enemyX[esi]
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    ; Also clear side positions for level 2+
    cmp currentLevel, 2
    jl SkipEnemyClearY
    
    inc dl
    cmp dl, 79
    jg SkipRightClear
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    SkipRightClear:
        sub dl, 2
        cmp dl, 1
        jl SkipEnemyClearY
        call Gotoxy
        mov al, ' '
        call WriteChar
    
    SkipEnemyClearY:
        ; Only draw if enemy is on visible screen
        mov dh, enemyY[esi]
        cmp dh, 23
        jg ExitDrawEnemy
        cmp dh, 2
        jl ExitDrawEnemy
        
        ; Draw current position
        mov dl, enemyX[esi]
        call Gotoxy
        
        mov eax, red
        call SetTextColor
        mov al, 'V'
        call WriteChar
        jmp ExitDrawEnemy
    
    ClearEnemyPosition:
        ; Enemy was destroyed, clear its last known position
        mov dh, enemyY[esi]
        cmp dh, 25
        jg ExitDrawEnemy
        cmp dh, 0
        jl ExitDrawEnemy
        
        mov dl, enemyX[esi]
        cmp dl, 80
        jge ExitDrawEnemy
        cmp dl, 0
        jl ExitDrawEnemy
        
        call Gotoxy
        mov al, ' '
        call WriteChar
        
        ; Clear surrounding positions too
        inc dl
        cmp dl, 79
        jg ClearLeft
        call Gotoxy
        mov al, ' '
        call WriteChar
        
        ClearLeft:
            sub dl, 2
            cmp dl, 1
            jl ExitDrawEnemy
            call Gotoxy
            mov al, ' '
            call WriteChar
    
    ExitDrawEnemy:
        ret
DrawSingleEnemy ENDP

;==================================================
; Draw Enemy Bullets
;==================================================
DrawEnemyBullets PROC
    mov ecx, MAX_ENEMY_BULLETS
    mov esi, 0
    
    DrawEnemyBulletLoop:
        call DrawSingleEnemyBullet
        inc esi
        loop DrawEnemyBulletLoop
    
    ret
DrawEnemyBullets ENDP

;==================================================
; Draw Single Enemy Bullet - Helper procedure
;==================================================
DrawSingleEnemyBullet PROC
    cmp enemyBulletActive[esi], 0
    je ClearEnemyBulletPosition
    
    ; Clear previous position (bullet moved down one)
    mov dh, enemyBulletY[esi]
    cmp dh, 3
    jle SkipEnemyBulletClear
    dec dh
    
    mov dl, enemyBulletX[esi]
    call Gotoxy
    mov al, ' '
    call WriteChar
    
    SkipEnemyBulletClear:
        ; Only draw if bullet is on visible screen
        mov dh, enemyBulletY[esi]
        cmp dh, 24
        jg ExitDrawEnemyBullet
        cmp dh, 2
        jl ExitDrawEnemyBullet
        
        ; Draw current position
        mov dl, enemyBulletX[esi]
        call Gotoxy
        
        mov eax, red
        call SetTextColor
        mov al, '*'
        call WriteChar
        jmp ExitDrawEnemyBullet
    
    ClearEnemyBulletPosition:
        ; Enemy bullet was destroyed, clear its last position
        mov dh, enemyBulletY[esi]
        cmp dh, 25
        jg ResetEnemyBulletPos
        cmp dh, 0
        jl ResetEnemyBulletPos
        
        mov dl, enemyBulletX[esi]
        cmp dl, 80
        jge ResetEnemyBulletPos
        cmp dl, 0
        jl ResetEnemyBulletPos
        
        call Gotoxy
        mov al, ' '
        call WriteChar
        
        ResetEnemyBulletPos:
            ; Reset position to prevent future clearing attempts
            mov enemyBulletX[esi], 255
            mov enemyBulletY[esi], 255
    
    ExitDrawEnemyBullet:
        ret
DrawSingleEnemyBullet ENDP

;==================================================
; FIXED Save High Score Procedure
;==================================================
SaveHighScore PROC
    ; Create/append to file
    mov edx, OFFSET filename
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je CreateNewFile
    
    ; File exists, close it and open for append
    call CloseFile
    mov edx, OFFSET filename
    call CreateOutputFile
    mov fileHandle, eax
    jmp WriteScore
    
    CreateNewFile:
        ; Create new file
        mov edx, OFFSET filename
        call CreateOutputFile
        mov fileHandle, eax
    
    WriteScore:
        cmp fileHandle, INVALID_HANDLE_VALUE
        je FileError
        
        ; Write player name
        mov edx, OFFSET playerName
        call StrLength
        mov ecx, eax
        mov edx, OFFSET playerName
        mov eax, fileHandle
        call WriteToFile
        
        ; Write separator " - Score: "
        mov edx, OFFSET separatorMsg
        call StrLength
        mov ecx, eax
        mov edx, OFFSET separatorMsg
        mov eax, fileHandle
        call WriteToFile
        
        ; Convert score to string and write it
        mov eax, score
        mov edx, OFFSET scoreBuffer
        call ConvertScoreToString
        
        mov edx, OFFSET scoreBuffer
        call StrLength
        mov ecx, eax
        mov edx, OFFSET scoreBuffer
        mov eax, fileHandle
        call WriteToFile
        
        ; Write newline
        mov edx, OFFSET newlineChars
        mov ecx, 2  ; CR+LF
        mov eax, fileHandle
        call WriteToFile
        
        ; Close file
        mov eax, fileHandle
        call CloseFile
    
    FileError:
        ret
SaveHighScore ENDP

;==================================================
; Convert Score to String - FIXED VERSION
;==================================================
ConvertScoreToString PROC
    ; Input: EAX = score, EDX = buffer address
    ; Clear the buffer first
    push edi
    push ecx
    push eax
    
    mov edi, edx
    mov ecx, 20
    ClearBuffer:
        mov BYTE PTR [edi], 0
        inc edi
        loop ClearBuffer
    
    pop eax
    pop ecx
    pop edi
    
    ; Now convert number to string
    push ebx
    push ecx
    push edx
    push esi
    
    mov edi, edx        ; EDI points to buffer
    mov ebx, 10         ; Base 10
    mov ecx, 0          ; Digit counter
    
    ; Handle zero case
    cmp eax, 0
    jne StartConversion
    mov BYTE PTR [edi], '0'
    inc edi
    mov BYTE PTR [edi], 0
    jmp ConversionDone
    
    StartConversion:
        ; Convert digits (they come out in reverse order)
        ConvertLoop:
            xor edx, edx
            div ebx             ; EAX = quotient, EDX = remainder
            add dl, '0'         ; Convert remainder to ASCII
            push edx            ; Push digit onto stack
            inc ecx             ; Count digits
            test eax, eax
            jnz ConvertLoop
        
        ; Pop digits from stack to get correct order
        WriteDigits:
            pop eax
            mov [edi], al
            inc edi
            loop WriteDigits
        
        ; Null terminate
        mov BYTE PTR [edi], 0
    
    ConversionDone:
        pop esi
        pop edx
        pop ecx
        pop ebx
        ret
ConvertScoreToString ENDP

;==================================================
; Show Game End
;==================================================
ShowGameEnd PROC
    call Clrscr
    mov dh, 10
    mov dl, 20
    call Gotoxy
    
    cmp currentLevel, 4
    jg ShowWinMessage
    
    ; Game over
    mov eax, red
    call SetTextColor
    mov edx, OFFSET gameOverMsg
    call WriteString
    jmp ShowFinalScore
    
    ShowWinMessage:
        mov eax, green
        call SetTextColor
        mov edx, OFFSET gameWonMsg
        call WriteString
    
    ShowFinalScore:
        mov dh, 12
        mov dl, 20
        call Gotoxy
        mov eax, yellow
        call SetTextColor
        mov edx, OFFSET finalScoreMsg
        call WriteString
        mov eax, score
        call WriteDec
        
        mov dh, 14
        mov dl, 20
        call Gotoxy
        mov eax, white
        call SetTextColor
        mov edx, OFFSET playerName
        call WriteString
    
    ret
ShowGameEnd ENDP

END main