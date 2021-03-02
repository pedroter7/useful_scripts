#!/bin/bash

#########################################################
### Use this script to create a C++ project structure
### instead of using an IDE for that.
###
### Author: Pedro T Freidinger (pedrotersetti3@gmail.com)
### License: MIT
### Version: 0.1 (25 feb. 2021)
#########################################################

#########################################################
### What this script does in current version (1.0):
###
### Creates a project structured as follows:
###
### - project_name/
### |-- src/
###   |-- main.cpp (prevent this using -no-main flag)
### |-- include/
### |-- README.md (prevent this using -no-git flag)
###
#########################################################

#########################################################
### Usage:
###
### <command> <project_name> [options]
#########################################################

#########################################################
### Options:
###
### -h: Prints this help text and exits
### -no-git: Creates a project without calling git init
### -about '<text>': Only works if -no-git is not passed.
###	uses '<text>' as a description text for README.md
### -no-main: Won't create a main.cpp file.
###
#########################################################

print_help_and_exit() {
	echo -e "\nUsage:\n\t$0 <project_name> [options]"
	echo -e "\nOptions:\n"
	echo -e "\t-h: Prints this help text and exits (won't have effect if is not the only parameter)\n"
	echo -e "\t-no-git: Creates a project without calling git init\n"
	echo -e "\t-about '<text>': Only works if -no-git is passed. Uses '<text>' as description text for creating a README.md\n"
	echo -e "\t-no-main: Won't create a main.cpp file\n"
	exit 1
}


no_git=false
about=false
about_text=""
no_main=false

if [[ "$1" =~ ^- || $# -eq 0 ]] 
then
	print_help_and_exit
fi

project_name="$1"
shift

# Parse parameters
while [[ $# -gt 0 ]]
do
param="$1"

case $param in
	-no-git)
		no_git=true
		shift
		;;
	-about)
		about=true
		about_text="$2"
		shift
		shift
		;;
	-no-main)
		no_main=true
		shift
		;;
	*)
		shift
		;;
esac
done

create_directory_structure() {
	mkdir -p ./${project_name}/src
	mkdir -p ./${project_name}/include
}

init_git() {
	if [ "$no_git" = false ]
	then
		cd ./${project_name}
		git init
		if [[ "$about" = true ]]
		then
			echo -e "# ${project_name}\n\n${about_text}" > README.md
		fi
		git add *
		git commit -m "Initial commit"
		cd ..
	fi
}

create_main_code() {
	if [[ "$no_main" = false ]]
	then
		cd ./${project_name}
		echo -e "#include <iostream>\n\n" > ./src/main.cpp
		echo -e "int main(int argc, char **argv) {" >> ./src/main.cpp
		echo -e "\tstd::cout << \"Hello, world!\" << std::endl;" >> ./src/main.cpp
		echo -e "\treturn 0;" >> ./src/main.cpp
		echo -e "}" >> ./src/main.cpp
		cd ..
	fi
}

create_directory_structure
create_main_code
init_git
