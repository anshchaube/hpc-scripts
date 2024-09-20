# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

#### CARDINAL #################################

source ~/.cardinal.sh

#######################################################



#### NEK5000 + NEKRS - IF MODULES ARE SIMILAR #################################

#source ~/.nek_both.sh

#######################################################

#### NEK5000 ONLY SETTINGS #################################

#source ~/.nek5k.sh

#######################################################


#### NEKRS ONLY SETTINGS #######################################

#source ~/.nekrs.sh

############################################################

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
