#!/bin/sh

if [ "$DESKTOP_SESSION" = "ubuntu" ]; then 
   sleep 10s
   killall conky
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/CPU Load Panel (8-core)" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/CPU Loads Process Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/CPU Vitals Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/Connections Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/Date Time Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/GPU Vitals Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/IP Traffic Rate Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/Partition Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/RAM Loads Process Panel" &
   cd "$HOME/.conky/MHz_conky_widgets"
   conky -c "$HOME/.conky/MHz_conky_widgets/Syslog Panel" &
   exit 0
fi
