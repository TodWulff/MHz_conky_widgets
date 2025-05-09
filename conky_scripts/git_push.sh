#!/bin/sh

# Check if any parameters were provided directly
if [ $# -eq 0 ]; then
    echo "Commit message must be provided - aborting..."
    exit 1
else
    # Combine all parameters into a single commit message
    params="$@"
    
    echo "Pushing Conky widgets and scripts to github repo."
    echo "Commit Message: $params"
    
    cd ~/.conky/MHz_conky_widgets/
    git fetch && git status
    git add .
    git commit -m "$params"
    git push
    echo "Pushed Conky widgets and scripts to github repo"
    echo "Commit Message: $params"
fi