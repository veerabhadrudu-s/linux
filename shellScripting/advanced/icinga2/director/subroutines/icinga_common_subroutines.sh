: <<BOC
THis file has common subroutines related to icinga.
BOC

function restructureArgsUsingDoubleQuotesEscapeChar(){

        local i j VALUE TEMP NEW_ARGS_STRING="";
        [[ $# -eq 0 ]] && { printf ""; return 0; };

#       printf "Input arguments to the function - ${FUNCNAME[0]} is $*\n";
        # Below For Loop will re-structure the input args based on double-quote escape character to allow comma's in input csv row .
        for((i=1;i<=$#;i++))
        do
                echo -n "${!i}" | egrep -v '^".*' &>/dev/null && { NEW_ARGS_STRING=${NEW_ARGS_STRING}" "${!i}; continue; };
                VALUE="${!i}";VALUE=${VALUE:1};
                for((j=i+1;j<=$#;j++))
                do
                        TEMP="${!j}";
                        echo -n "${TEMP}" | egrep -v '.*"$' &>/dev/null && { VALUE=${VALUE}","${TEMP}; continue; };
                        VALUE=${VALUE}","${TEMP:0:$(( ${#TEMP} - 1 ))};
                        NEW_ARGS_STRING=${NEW_ARGS_STRING}" "${VALUE};
                        i=${j};
                        break;
                done
        done
	#Removing front extra space.This extra space causing icinga commands objects not working.
	NEW_ARGS_STRING=${NEW_ARGS_STRING:1};
	printf "${NEW_ARGS_STRING}" && return 0;
}


