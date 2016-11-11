# start our shared terminal
if [[ $(pgrep tmux) == '' ]];then
    tmux new -s pair
else
    tmux attach
fi
