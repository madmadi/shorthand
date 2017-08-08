#!/bin/bash

# Constants
HOME=~
PARAMS=$(($#))
KEYWORD=${@: $PARAMS}
COMMAND=$(echo ${@:1:$(($#-1))} | sed -E 's/ as$//g')

PL=22 # Preserved head lines @ ~/.shorthands file

# Force option -f
if [[ ! -z $(echo $@ | grep '\-f') ]]; then FORCE=true; fi

# Shorthands list
shorthandList(){
	local pl="+$((PL+1))"
	local splitter=': '
	if [[ -z $(tail --lines=$pl $HOME/.shorthand) ]];
		then isEmpty='[ Empty ]'
	fi
	echo Shorthands list $isEmpty
	tail --lines=$pl $HOME/.shorthand | \
	sed -En "s/=\"/$splitter/p" | \
	# sed -E "s/${splitter}echo / [Value]${splitter}/" | \
	sed -E 's/(alias |"\;)//g' | nl
}

searchShorthand(){
	shorthandList | \
	tail --lines="+$PL" | \
	grep -E "(.*: .*$*.*|.*$*.*: .*)"
}

deleteShorthand(){
	local line=0
	if [ $1 -gt 0 ]; then
		line=$(($1+PL))
		sed -ie "${line}d" $HOME/.shorthand
	fi
}

applyShorthands(){
	source $HOME/.shorthand
}

changeShorthand(){
	Alias=$(cat $HOME/.shorthand | grep -E "alias $KEYWORD=\".*\"")
	sed -ieE "s/$Alias/alias $KEYWORD=\"$COMMAND\"\;/g" $HOME/.shorthand
}

printHelp(){
	echo
	echo Usage: shorthand \<command\/value\> as \<keyword\>
	echo eg. shorthand echo hello world as hello,
	echo "    then you can call just 'hello' instead of 'echo hello world'"
	echo
	echo "Other Commands"
	echo "   l | list                   list of all shorthands"
	echo "   s | search <query>         search query in shorthands"
	echo "   d | delete <shorthand-id>  delete shorthand from the list"
	echo "   a | apply                  makes shorthands available for the current session"
	echo "   help                       prints this page"
	echo "   version                    prints shorthand version"
	echo
	echo To make shorthands available for the current session
	echo run \'source shorthand apply\' or \'. sho a\'
	echo
	echo Also you can call \'sho\' instead of \'shorthand\'.
}

printVersion(){
	echo Shorthand version 0.0.1
}

addShorthand(){
	# Trust minimum inputs
	if [ $PARAMS -lt 2 ]; then
		if [ $PARAMS -lt 1 ]; then
			echo Try -h to help.
			exit -1;
		fi
		echo Missing shorthand <keyword>.
		exit -1;
	fi

	# has valid keyword?
	if [[ $KEYWORD =~ " " ]]; then
		echo Invalid keyword \'$KEYWORD\'.
		exit -1;
	fi

	isValue=false
	# has valid command?
	type $(echo $COMMAND | cut -d " " -f1) > /dev/null 2>/dev/null
	if [ $? -ne 0 ]; then
		read -r -p "'$COMMAND' is an invalid command, do you want to save it as a value [Y/n]? " REPLY
		case "$REPLY" in
			[nN] | no | No | NO) exit -1;;
			*) COMMAND="echo $COMMAND"; isValue=true;;
		esac
	fi

	# Search for duplicate shorthand
	if [[ ! -z $(shorthandList | grep -E "	$KEYWORD: $COMMAND$") ]]; then
		echo No need, you\'ve done it before just call it. && exit
	fi

	# Search for other aliases command
	if [[ ! -z $(shorthandList | grep -E ".*: $COMMAND$") ]]; then
		echo "$COMMAND shorthands:"
		shorthandList | grep -E ".*: $COMMAND$"
		read -r -p "'$COMMAND' has shorthand(s) before, whould you like to add another [y/N]? " REPLY
		case "$REPLY" in
			[yY] | yes | Yes | YES);;
			*) exit -1;;
		esac
	fi

	# Search for other aliases keyword conflict
	if [[ ! -z $(shorthandList | grep -E "	$KEYWORD: .*") ]]; then
		target_cmd=$(shorthandList | grep -E "	$KEYWORD: .*" | sed -En "s/.*$KEYWORD: //p")
		read -r -p "'$KEYWORD' is already referd to '${target_cmd}', whould you like to change it [y/N]? " REPLY
		case "$REPLY" in
			[yY] | yes | Yes | YES) changeShorthand && exit;;
			*) exit -1;;
		esac
	fi

	# Search for commands conflict
	type $KEYWORD > /dev/null 2>/dev/null
	if [ $? -eq 0 ]; then
		read -r -p "'$KEYWORD' is a predefined keyword, do you want to override it [y/N]? " REPLY
		case "$REPLY" in
			[yY] | yes | Yes | YES);;
			*) exit -1;;
		esac
	fi

	# Prepare command completion
	local comp_name=$(echo _$COMMAND | sed -E 's/ .+$//g; s/\-/_/g')
	local func_name=$(echo _$COMMAND | sed 's/[ \-]/_/g')
	local completion=$(echo "&& complete -F $func_name $KEYWORD")

	# If has more than one word
	if [ `echo $COMMAND | wc -w` -gt 1 ]; then
		completion="&& makeCompletionWrapper $comp_name $func_name $COMMAND $completion"
	fi

	# Value doesn't need to command completion
	if $isValue; then completion=";"; fi

	# Disable alias auto complation
	completion=""

	# Write to file
	Alias="alias $KEYWORD=\"$COMMAND\";"
	echo $Alias >> $HOME/.shorthand
	. $HOME/.shorthand;

	echo "Done, in the new session or after run command 'source shorthand apply'"
	if $isValue;
		then echo "your value will be available"
		else echo "you can call '$KEYWORD' instead of $COMMAND"
	fi
}

# Make .bashrc ready to write
if [ ! -f $HOME/.bashrc ]; then
	touch $HOME/.bashrc;
	echo '# bashrc' > $HOME/.bashrc;
	echo >> $HOME/.bashrc;
fi

# Add .shorthand to ~/.bashrc
if [[ -z $(grep '##### SHORTHAND BLOCK START ####' $HOME/.bashrc) ]]; then
	echo >> $HOME/.bashrc
	echo '##### SHORTHAND BLOCK START ####' >> $HOME/.bashrc
	echo "# It makes 'shorthand' to work" >> $HOME/.bashrc
	echo '[ -s "$HOME/.shorthand" ] && source ~/.shorthand' >> $HOME/.bashrc
	echo '##### SHORTHAND BLOCK END ######' >> $HOME/.bashrc
fi

# Make file ready to write
if [ ! -f $HOME/.shorthand ]; then
	touch $HOME/.shorthand;
	echo "## Shorthands" > $HOME/.shorthand;
	echo "#############" >> $HOME/.shorthand;
	echo >> $HOME/.shorthand;
	echo "# Functions" >> $HOME/.shorthand;
	echo "
makeCompletionWrapper(){
	local function_name=\"\$2\"
	local arg_count=\$((\$#-3))
	local comp_function_name=\"\$1\"
	shift 2
	local fn=\"
	\${function_name}(){
		((COMP_CWORD+=\$arg_count))
		COMP_WORDS=(\"\$@\" \${COMP_WORDS[@]:1})
		\$comp_function_name
		return 0
	}\"
	eval \"\$fn\"
}
	" >> $HOME/.shorthand;
	echo "# Aliases" >> $HOME/.shorthand;
	echo >> $HOME/.shorthand;
fi

# Options
case "$1" in
	l | -l | list ) shorthandList;;
	s | -s | search ) searchShorthand ${@:2};;
	d | -d | delete ) deleteShorthand $2;;
	a | -a | apply ) applyShorthands;;
	h | -h | help | --help ) printHelp;;
	v | -v | version | --version ) printVersion;;
	*) addShorthand;;
esac