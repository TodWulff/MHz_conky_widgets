#!/bin/sh

# Check if any parameters were provided directly
if [ $# -eq 0 ]; then
    echo ""
    echo "Commit message must be provided - aborting..."
    echo ""
    exit 1
else
    # Combine all parameters into a single commit message
    params="$@"
    echo ""
    echo "Pushing Conky widgets and scripts to github repo."
    echo "Commit Message: $params"
    echo ""
    cd ~/.conky/MHz_conky_widgets/
    git fetch && git status
    git add .
    git commit -m "$params"
    git push
    echo ""
    echo "Pushed Conky widgets and scripts to github repo"
    echo "Commit Message: $params"
    echo ""
fi

#	I love AIs:
#	
#	Instead of relocating the script to ~/.local/bin/, can I leave the script inside of the repo and then create a link to it, placing the link in  ~/.local/bin/?
#	
#	Yes, absolutely! Creating a symbolic link is an excellent approach. This way, you can keep your script in the repository and still access it from anywhere. Here's how to do it:
#	
#	bash
#	# 1. Make sure the script is executable
#	chmod +x ~/.conky/MHz_conky_widgets/your_script_name
#	
#	# 2. Create a symbolic link in ~/.local/bin/
#	# Make sure ~/.local/bin exists
#	mkdir -p ~/.local/bin
#	
#	# 3. Create the symbolic link (let's call it "conky-push")
#	ln -s ~/.conky/MHz_conky_widgets/your_script_name ~/.local/bin/conky-push
#	
#	# 4. If ~/.local/bin is not already in your PATH, add it
#	# Check if it's in your PATH
#	echo $PATH | grep -q "$HOME/.local/bin"
#	if [ $? -ne 0 ]; then
#	    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
#	    # Apply the change to current session
#	    export PATH="$HOME/.local/bin:$PATH"
#	    echo "Added ~/.local/bin to PATH"
#	fi
#	With this approach:
#	
#	Your script stays in the repository where it belongs
#	Any updates to the script in the repo will be immediately available through the link
#	You can still execute it from anywhere by typing conky-push "Your commit message"
#	This is often the preferred method for scripts that are part of a project or repository.
