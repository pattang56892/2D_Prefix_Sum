function Show-InteractiveGitHistory {
    # --- START OF ENCODING FIX ---
    # Store the original encoding and set it to UTF8 (65001) for correct Git output
    $global:OriginalConsoleEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 
    # --- END OF ENCODING FIX ---

    # --- 1. COMMIT RETRIEVAL & PARSING (FIXED: Robust string handling and simplified slicing) ---

    # Define a unique, less-likely-to-be-in-commit-message separator
    $commitSeparator = "---END_OF_COMMIT_BLOCK---"
    
    # Use format: Hash|Date<NL>Full Message Body<NL>Separator
    $logFormat = "%H|%ad%n%B%n$commitSeparator" 
    
    # *** FIX: Use a subexpression ( $($cmd) ) and Out-String to force output 
    #          to be captured as a single, large string, preventing line-by-line object emission.
    $logOutput = $(git log -n 20 --no-patch --format=format:$logFormat --date=short) | Out-String

    if (-not $logOutput -or $logOutput.Trim() -eq $commitSeparator.Trim()) {
        Write-Host "No commits found in this repository." -ForegroundColor Red
        # Restore encoding before returning
        [Console]::OutputEncoding = $global:OriginalConsoleEncoding
        return
    }

    $commitList = @()
    # Split the single string by the unique marker to get individual raw commit blocks.
    $rawCommits = $logOutput -split $commitSeparator | Where-Object { $_ -match '\S' } 

    # Parse raw commit blocks into objects
    $rawCommits | ForEach-Object {
        # Split the block by newline.
        # .Trim() cleans up whitespace from the separator splitting.
        $lines = ($_.Trim() -split "`n") | Where-Object { $_ -match '\S' } 

        if ($lines.Count -gt 0) {
            # First line is HASH|DATE
            $metadata = $lines[0] -split '\|'
            $hash = $metadata[0]
            # Check for date existence
            $date = if ($metadata.Count -gt 1) { $metadata[1].Trim() } else { "Unknown Date" }

            # Remaining lines are the message body.
            $messageLines = $lines | Select-Object -Skip 1 
            
            # --- SHOWING FIRST 10 LINES ---
            $linesToDisplay = $messageLines | Select-Object -First 10
            
            # Join the lines that actually exist, indented for display
            $truncatedMessage = ($linesToDisplay -join "`n    ") 

            # Join the full message lines
            $fullMessage = $messageLines -join "`n" 
            
            # --- FIX: Check hash length before Substring ---
            # If the hash is shorter than 7 chars for some reason, just use the hash itself.
            $shortHash = if ($hash.Length -ge 7) { $hash.Substring(0, 7) } else { $hash }

            $commitList += [PSCustomObject]@{
                Index       = 0
                Hash        = $hash
                Date        = $date
                Message     = $truncatedMessage # Truncated message for initial display
                FullMessage = $fullMessage # Store full message for export/detail view
                ShortHash   = $shortHash
            }
        }
    }

    # Add index numbers
    for ($i = 0; $i -lt $commitList.Count; $i++) {
        $commitList[$i].Index = $i + 1
    }

    # --- 2. INTERACTIVE LOOP (With Encoding Restoration) ---

    do {
        # Display commit list 
        Write-Host "`n=== RECENT COMMITS (Showing first 10 lines of message) ===" -ForegroundColor Cyan
        $commitList | ForEach-Object {
            Write-Host ("{0}. {1} ({2}) -" -f $_.Index, $_.ShortHash, $_.Date) -ForegroundColor White -NoNewline
            
            $msgLines = $_.Message -split "`n"
            Write-Host (" {0}" -f $msgLines[0]) -ForegroundColor White # First line (subject)
            
            # Display subsequent lines indented
            $msgLines | Select-Object -Skip 1 | ForEach-Object {
                # We need to ensure we don't print blank lines if the commit message was short
                if ($_.Trim() -ne "") {
                    Write-Host "    $_" -ForegroundColor DarkGray 
                }
            }
            if ($msgLines.Count -gt 1) {
                Write-Host "" # Extra newline after a multi-line entry for readability
            }
        }

        # Interactive selection
        Write-Host "`nSelect a commit to view details (1-$($commitList.Count)), or export your selected commit to Notepad (1P-$($commitList.Count)P), or 'q' to quit:" -ForegroundColor Yellow
        $selection = Read-Host

        if ($selection -eq 'q') {
            Write-Host "Exiting." -ForegroundColor Gray
            # --- ENCODING RESTORATION FIX ---
            [Console]::OutputEncoding = $global:OriginalConsoleEncoding
            # --- END OF ENCODING RESTORATION FIX ---
            break # Exit the do/while loop
        }

        $isExport = $false
        $selectedIndex = 0
        $validSelection = $true

        # Detect if user wants to export (e.g. 3P or 10p)
        if ($selection -match '^(\d+)[Pp]$') {
            $isExport = $true
            $selectedIndex = [int]$Matches[1]
        }
        elseif ([int]::TryParse($selection, [ref]$selectedIndex)) {
            $isExport = $false
        }
        else {
            Write-Host "Invalid selection format. Enter a number (e.g. 3) or number+P (e.g. 3P)." -ForegroundColor Red
            $validSelection = $false
        }

        if ($validSelection -and ($selectedIndex -lt 1 -or $selectedIndex -gt $commitList.Count)) {
            Write-Host ("Invalid selection. Please enter a number between 1 and {0}." -f $commitList.Count) -ForegroundColor Red
            $validSelection = $false
        }

        # If selection is valid, process it
        if ($validSelection) {
            $selectedCommit = $commitList[$selectedIndex - 1]

            # Fetch full commit details (Done inside the loop, only when needed)
            # Use --no-pager to ensure the output is returned directly
            $commitDetails = git --no-pager show $selectedCommit.Hash

            if ($isExport) {
                # Export to Notepad
                $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "GitCommit_$($selectedCommit.ShortHash).txt")

                $exportContent = @()
                $exportContent += "=== COMMIT DETAILS ==="
                $exportContent += "Commit: $($selectedCommit.ShortHash)"
                $exportContent += "Date: $($selectedCommit.Date)"
                $exportContent += "Message:`n$($selectedCommit.FullMessage)" 
                $exportContent += ""
                $exportContent += "=== CHANGES ==="
                $exportContent += $commitDetails

                $exportContent | Out-File -FilePath $tempFile -Encoding UTF8
                Write-Host "`nCommit exported to Notepad: $tempFile" -ForegroundColor Green
                Start-Process notepad.exe $tempFile
            }
            else {
                # Display commit details in console
                Write-Host "`n=== COMMIT DETAILS ===" -ForegroundColor Green
                Write-Host ("## Commit: {0}" -f $selectedCommit.ShortHash) -ForegroundColor White
                Write-Host ("**Date:** {0}" -f $selectedCommit.Date) -ForegroundColor White
                Write-Host ("**Message:**`n{0}" -f $selectedCommit.FullMessage) -ForegroundColor White 
                Write-Host "`n### Changes:" -ForegroundColor White

                $inDiff = $false
                $inCodeBlock = $false

                $commitDetails -split "`n" | ForEach-Object {
                    if ($_ -match "^diff --git") {
                        if ($inCodeBlock) { Write-Host '```' -ForegroundColor Gray; $inCodeBlock = $false }
                        Write-Host "`n#### $_" -ForegroundColor Cyan
                        $inDiff = $true
                    }
                    elseif ($_ -match "^index " -and $inDiff) {
                        Write-Host '```diff' -ForegroundColor Gray
                        Write-Host $_ -ForegroundColor Gray
                        $inCodeBlock = $true
                    }
                    elseif ($_ -match "^@@.*@@") { Write-Host $_ -ForegroundColor Yellow }
                    elseif ($_ -match "^-") { Write-Host $_ -ForegroundColor Red }
                    elseif ($_ -match "^\+") { Write-Host $_ -ForegroundColor Green }
                    elseif ($_ -match "^---" -or $_ -match "^\+\+\+") { Write-Host $_ -ForegroundColor Gray }
                    elseif ($inCodeBlock) { Write-Host $_ -ForegroundColor Gray }
                    elseif ($_ -match "^commit ") { Write-Host "`n### $_" -ForegroundColor White }
                    elseif ($_ -match "^Author: ") { Write-Host "**Author:**" -ForegroundColor White; Write-Host ($_ -replace "^Author:\s*", "") -ForegroundColor White }
                    elseif ($_ -match "^Date: ") { Write-Host "**Date:**" -ForegroundColor White; Write-Host ($_ -replace "^Date:\s*", "") -ForegroundColor White }
                    elseif ($_ -match "^\s{4}") { Write-Host $_ -ForegroundColor White }
                    else {
                        if ($inCodeBlock) { Write-Host '```' -ForegroundColor Gray; $inCodeBlock = $false }
                        Write-Host $_ -ForegroundColor White
                    }
                }

                if ($inCodeBlock) {
                    Write-Host '```' -ForegroundColor Gray
                }

                Write-Host "`n=== END OF COMMIT ===" -ForegroundColor Green
            }
        }

    } while ($true)
}

Show-InteractiveGitHistory