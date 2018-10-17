#!/usr/bin/env bash

. /hive/custom/hive_ccminer_veros/h-manifest.conf

threads=`echo "threads" | nc -w ${API_TIMEOUT} localhost $API_PORT | tr -d '\0'` #&& echo $threads
if [[ $? -ne 0  || -z $threads ]]; then
	echo -e "${YELLOW}Failed to read ${CUSTOM_NAME} stats from localhost:${API_PORT}${NOCOLOR}"
else
   summary=`echo "summary" | nc -w ${API_TIMEOUT} localhost $API_PORT | tr -d '\0'` #&& echo $threads
   uptime=`echo "$summary" |  tr ';' '\n' | grep -m1 'UPTIME=' | sed -e 's/.*=//'`
	algo=`echo "$summary" | tr ';' '\n' | grep -m1 'ALGO=' | sed -e 's/.*=//'`
	ac=`echo "$summary" | tr ';' '\n' | grep -m1 'ACC=' | sed -e 's/.*=//'`
	rj=`echo "$summary" | tr ';' '\n' | grep -m1 'REJ=' | sed -e 's/.*=//'`
	striplines=`echo "$threads" | tr '|' '\n' | tr ';' '\n' | tr -cd '\11\12\15\40-\176'`

	cctemps=(`echo "$striplines" | grep 'TEMP=' | sed -e 's/.*=//'`)
	cckhs=(`echo "$striplines" | grep 'KHS=' | sed -e 's/.*=//'`)
	ccbusids=(`echo "$striplines" | grep 'BUS=' | sed -e 's/.*=//'`)
	bus_numbers=$(jq -sc . <<< "$ccbusids")

   echo $gpu_stats

	for (( i=0; i < ${#cckhs[@]}; i++ )); do
		#if temp is 0 then driver or GPU failed
#		[[ ${cctemps[$i]} == "0.0" ]] && cckhs[$i]="0.0"

      cckhs[$i]=`echo ${cckhs[$i]} | awk '{print $1/1000}'`
		if [[ `echo ${cckhs[$i]} | awk '{ print ($1 >= 1000) ? 1 : 0 }'` == 1 ]]; then # > 1Mh
			#[[ -z $nvidiastats ]] && nvidiastats=`gpu-stats nvidia` #a bit overhead in calling nvidia-smi again
			busid=`echo ${ccbusids[$i]} | awk '{ printf("%02x:00.0", $1) }'` #ccbus is decimal
			load_i=`echo "$gpu_stats" | jq ".busids|index(\"$busid\")"`
			if [[ $load_i != "null" ]]; then #can be null on failed driver
				load=`echo "$gpu_stats" | jq -r ".load[$load_i]"`
			echo "$gpu_stats" | jq -r ".temp[$load_i]"
			   #echo ${cctemps[$i]}
				[[ -z $load || $load -le 10 ]] &&
					echo -e "${RED}Hash on GPU$i is in GH/s (${cckhs[$i]} kH/s) but Load is detected to be only $load%${NOCOLOR}" &&
					cckhs[$i]="0.0"
			fi
		fi

		#khs=`echo $khs ${cckhs[$i]} | awk '{ printf("%.3f", $1 + $2) }'`
		khs=`echo $khs ${cckhs[$i]} | awk '{ printf("%.3f", $1 + $2) }'`
	done

	khs=`echo $khs | sed -E 's/^( *[0-9]+\.[0-9]([0-9]*[1-9])?)0+$/\1/'` #1234.100 -> 1234.1

	stats=$(jq -n \
		--arg uptime "$uptime", --arg algo "$algo" \
		--argjson khs "`echo ${cckhs[@]} | tr " " "\n" | jq -cs '.'`" \
		--argjson temp "`echo ${cctemps[@]} | tr " " "\n" | jq -cs '.'`" \
		--argjson fan "`echo \"$striplines\" | grep 'FAN=' | sed -e 's/.*=//' | jq -cs '.'`" \
		--arg ac "$ac" --arg rj "$rj" --argjson bus_numbers "$bus_numbers" \
		'{$khs, $temp, $fan, $uptime, ar: [$ac, $rj], $bus_numbers, $algo}')
fi

echo $stats

