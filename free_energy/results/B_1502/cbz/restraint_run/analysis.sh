alchem=alchemical_analysis
if ! [ -x $(command -v $alchem) ]
then
    alchem=alchemical_analysis.py
    if ! [ -x $(command -v $PARMCHK) ]
    then
        echo -e "\n\talchemical_analysis[.py] not found. Quitting ..."
        exit 1
    fi
fi

alchemical_analysis -a AMBER -d . -p [01].[0-9]*/production/prod -q out -o . -r 5 -u kcal -s 0 -g -w -f 10 -t 300

