#!/bin/bash
version="0.4"

# Activate Chia Environment
appdir=`pwd`
cd ~/chia-blockchain
. ./activate
cd $appdir

# define some colors
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
bldgrn='\e[1;32m' # Bold Green
bldpur='\e[1;35m' # Bold Purple
txtrst='\e[0m'    # Text Reset

display_banner()
{
	echo -e "${bldgrn}"
	echo -e "           _          __ _              _                  _ "
	echo -e "          | |        / _| |            (_)                | |"
	echo -e "  __  ____| |  _ __ | |_| |_  __      ___ ______ _ _ __ __| |"
	echo -e "  \ \/ / _' | | '_ \|  _| __| \ \ /\ / / |_  / _' | '__/ _' |"
	echo -e "   >  < (_| | | | | | | | |_   \ V  V /| |/ / (_| | | | (_| |"
	echo -e "  /_/\_\__,_| |_| |_|_|  \__|   \_/\_/ |_/___\__,_|_|  \__,_|"
	echo -e " ------------------------------------------------------------${txtred}"
	echo -e " Interactive script to help with NFT tasks.       version $version${bldgrn}"
	echo -e " ------------------------------------------------------------"
}

mojo2xch()
{
    local mojo=$1
    local xch=""

    # cant do floating division in Bash but we know xch is always mojo/10000000000
    # so we can use string manipulation to build the xch value from mojo
    mojolength=`expr length $mojo`
    if [ $mojolength -eq 12 ]; then
        xch="0.$mojo"
    elif [ $mojolength -lt 12 ]; then
        temp=`printf "%012d" $mojo`
        xch="0.$temp"
    else
        off=$(($mojolength - 12))
        off2=$(($off + 1))
        temp1=`echo $mojo | cut -c1-$off`
        temp2=`echo $mojo | cut -c$off2-$mojolength`
        xch="$temp1.$temp2"
    fi
    echo "$xch"
}

get_nft_json()
{
	local id=$1
	local json=`curl -s https://api.mintgarden.io/nfts/$id`
	echo "$json"
}

get_nft_collection()
{
	local json=$1
	local nft_collection=`echo "$json" | jq '.data.metadata_json.collection.name' | cut --fields 2 --delimiter=\"`
	echo "$nft_collection"
}

get_nft_name()
{
	local json=$1
	local nft_name=`echo "$json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
	echo "$nft_name"
}

get_nft_coin_id()
{
	local id=$1
	local nft_coin_id=`chia wallet nft get_info -ni $id | grep "Current NFT coin ID" | cut -c 28-`
	echo "$nft_coin_id"
}

nft_details()
{
	local id=$1
	local val=$2
	local nft_json
	local nft_collection
	local nft_name
	local nft_coin_id

    nft_json=$(get_nft_json $id)
    nft_collection=`echo "$nft_json" | jq '.data.metadata_json.collection.name' | cut --fields 2 --delimiter=\"`
    nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
    nft_coin_id=$(get_nft_coin_id $id)

    echo -e " NFT ID:         ${txtrst}$id${txtgrn}"
    echo -e " NFT Collection: ${txtrst}$nft_collection${txtgrn}"
    echo -e " NFT Name:       ${txtrst}$nft_name${txtgrn}"
    echo -e " NFT Coin ID:    ${txtrst}$nft_coin_id${txtgrn}"
	echo -e " Wallet ID:      ${txtrst}$val${txtgrn}"
}

get_wallet_list()
{
	local wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
	echo "$wallet_list"
}

get_fingerprint()
{
	fingerprint=`chia wallet show | grep "fingerprint" | cut -c 24-`
	echo "$fingerprint"
}

get_my_dids()
{
	my_dids=`chia wallet show -w decentralized_id | grep "DID ID" | cut -c 28-`
	echo "$my_dids"
}

sleep_countdown()
{
	secs=$(($1))
	while [ $secs -gt 0 ]; do
	   echo -ne " $secs\033[0K\r"
	   sleep 1
	   : $((secs--))
	done
}

send_nft()
{
	local nft_id=$1
	local display=$2

	if [ "$nft_id" == "" ]; then
		read -p " NFT ID? " nft_id
	fi

	nft_wallet_id=$(get_wallet_id $nft_id)
	coin_id=$(get_nft_coin_id $nft_id)

	if [ "$display" == "true" ]; then
		echo ""
		echo -e " Searching for ${txtrst}$nft_id${bldgrn}..."
		echo ""
		nft_details $nft_id $nft_wallet_id
	fi

	# get destination wallet address
	echo ""
	read -p " Destination address? " destination

	# get fee to send in mojos
	echo ""
	fee_mojos=""
	read -p " [Enter] for 1 mojo fee, or specific number of mojos: " fee_mojos
	if [ "$fee_mojos" == "" ]; then
		fee_mojos="1"
	fi
	echo ""

	# convert fee_mojos to fee_xch
	fee_xch=$(mojo2xch $fee_mojos)

	# get the current fingerprint
	fingerprint=$(get_fingerprint)

	# build transfer command and display
	cmd="~/chia-blockchain/venv/bin/chia wallet nft transfer -f $fingerprint -i $nft_wallet_id -m $fee_xch -ni $coin_id -ta $destination"
	echo " COMMAND"
	echo -e " ${txtrst}$cmd${bldgrn}"

	# run transfer command
	echo ""
	read -p " Run command Y/N? " run
	if [ "$run" == "Y" ] || [ "$run" == "y" ]; then
		~/chia-blockchain/venv/bin/chia wallet nft transfer -f $fingerprint -i $nft_wallet_id -m $fee_xch -ni $coin_id -ta $destination
	fi
}

get_wallet_id()
{
	local nft_id=$1
	local nft_wallet_id=""

	wallet_list=$(get_wallet_list)

	# search for wallet id containing nft id
	for val in $wallet_list; do
		found="false"
		nft_id_list=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`
		for id in $nft_id_list; do
			if [ "$id" == "$nft_id" ]; then
				nft_wallet_id="$val"
			fi
		done
	done
	echo "$nft_wallet_id"
}

menu()
{
	echo ""
	echo " 1. View NFT details by NFT ID"
	echo " 2. Send NFT to Wallet Address"
	echo " 3. Get list of my NFTs"
	echo " 4. Get list of NFT IDs from Collection"
	echo " 5. Get list of Owner Wallets from NFT IDs"
	echo " 6. Get list of NFT Names from NFT IDs"
	echo " 7. Name generators"
	echo " 8. Pick Random NFT, Optional Airdrop"
	echo " 9. Batch Move NFTs to Profile/DID"
	echo " x. Exit"
	echo ""
	read -p " Selection: " menu_selection

	###########################################################
	# Exit menu
	###########################################################
	if [ "$menu_selection" == "X" ] || [ "$menu_selection" == "x" ] ||[ "$menu_selection" == "" ]; then
	   echo ""
	   exit
	fi

	###########################################################
	# View NFT details by NFT ID
	###########################################################
	if [ "$menu_selection" == "1" ]; then
		echo ""
		read -p " NFT ID? " nft_id
		echo -e " Searching for ${txtrst}$nft_id${bldgrn}..."
		echo ""
		nft_wallet_id=$(get_wallet_id $nft_id)
		nft_details $nft_id $nft_wallet_id
	fi

	###########################################################
	# Send NFT to Wallet Address
	###########################################################
	if [ "$menu_selection" == "2" ]; then
		echo ""
		nft_id=""
		send_nft $nft_id "true"
	fi

	###########################################################
	# Create a list of my NFTs
	###########################################################
	if [ "$menu_selection" == "3" ]; then
		echo ""
		wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
		echo -e " NFT Wallet IDs: ${txtrst}$wallet_list${bldgrn}"
		echo ""
		read -p " Wallet ID, or [Enter] for all, or [x] to cancel? " answer_wallet

		if [ "$answer_wallet" != "X" ] && [ "$answer_wallet" != "x" ]; then

			if [ "$answer_wallet" != "" ]; then
				wallet_list="$answer_wallet"
			fi

			all=0
			for val in $wallet_list; do
				echo ""
				echo " ==== Wallet ID: $val ===="

				c=`chia wallet nft list -i $val | grep "NFT identifier" | wc -l`
				nft_ids=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`

				for id in $nft_ids; do
					nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
					nft_collection=`echo "$nft_json" | jq '.data.metadata_json.collection.name' | cut --fields 2 --delimiter=\"`
					nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
					echo -e "${txtrst}$id [$nft_collection] $nft_name${bldgrn}"
				done

				echo -e " Wallet Total: ${txtrst}$c${bldgrn}"
				all=$(($all+$c))
			done

			echo ""
			echo -e " Total number of NFTs: ${txtrst}$all${bldgrn}"
		fi
	fi

	###########################################################
	# Get list of NFT IDs from Collection
	###########################################################
	if [ "$menu_selection" == "4" ]; then
		echo ""
		echo -e " You will need the Collection ID. You can find this on    ${txtrst}https://mintgarden.io${bldgrn}"
		echo -e ""
		echo -e " Search for your collection name ie. BattleKats which should result in a page with a URL like such:"
		echo -e "   ${txtrst}https://mintgarden.io/collections/battlekats-col1kmrzafjx6ej8w79tz5vnjt4w8xuq2p6nmnheelgwwu3rsgsar0fsxc4wud${bldgrn}"
		echo -e ""
		echo -e " You Collection ID is everything after the hyphen in the URL."
		echo -e " For example:   ${txtrst}col1kmrzafjx6ej8w79tz5vnjt4w8xuq2p6nmnheelgwwu3rsgsar0fsxc4wud${bldgrn}"
		echo -e ""
		read -p " Collection ID? " collection_id
		if [ "$collection_id" != "X" ] && [ "$collection_id" != "x" ]; then
			nfts=`curl -s https://api.mintgarden.io/collections/$collection_id/nfts/ids`
			echo -e "${txtrst}"
			nft_list=`echo "$nfts" | jq '.[].encoded_id' | cut --fields 2 --delimiter=\"`
			for id in $nft_list; do
				echo -e "$id"
			done
			echo -e "${txtgrn}"
		fi
	fi

	###########################################################
	# Get list of Owner Wallets from NFT IDs
	###########################################################
	if [ "$menu_selection" == "5" ]; then
		echo ""
		echo " 1. Single NFT ID"
		echo " 2. File of NFT IDs"
		echo ""
		read -p " Selection? " submenu_select
		if [ "$submenu_select" == "1" ]; then
			echo ""
			read -p " NFT ID? " nft_ids
		else
			echo ""
			read -p " Filename? " filename
			nft_ids=`cat $filename`
		fi
		echo ""
		read -p " Output to Screen or File S/F? " output_type
		if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
			read -p " Filename to save as? " outfile
			if [ -f "$outfile" ]; then
				rm $outfile
				touch $outfile
				fi
		fi

		n=1
		for id in $nft_ids; do
			nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
			nft_owner_wallet=`echo "$nft_json" | jq '.owner_address.encoded_id' | cut --fields 2 --delimiter=\"`
			#outputting to the console screen slows the script down
			if [ "$output_type" == "S" ] || [ "$output_type" == "s" ]; then
				echo -e "${txtrst}$nft_owner_wallet,$id${bldgrn}"
			fi
			if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
				echo "$nft_owner_wallet,$id" >> $appdir/$outfile
			fi
			n=$(($n+1))
		done
	fi

	###########################################################
	# Get list of NFT Names from NFT IDs"
	###########################################################
	if [ "$menu_selection" == "6" ]; then
		echo ""
		echo " 1. Single NFT ID"
		echo " 2. File of NFT IDs"
		echo ""
		read -p " Selection? " submenu_select
		if [ "$submenu_select" == "1" ]; then
			echo ""
			read -p " NFT ID? " nft_ids
		else
			echo ""
			read -p " Filename? " filename
			nft_ids=`cat $filename`
		fi
		echo ""
		read -p " Output to Screen or File S/F? " output_type
		if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
			read -p " Filename to save as? " outfile
			if [ -f "$outfile" ]; then
				rm $outfile
				touch $outfile
			fi
		fi

		n=1
		for id in $nft_ids; do
			nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
			nft_id=`echo "$nft_json" | jq '.encoded_id' | cut --fields 2 --delimiter=\"`
			nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
			if [ "$output_type" == "S" ] || [ "$output_type" == "s" ]; then
				echo -e "${txtrst}$nft_id,$nft_name${bldgrn}"
			fi
			if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
				echo "$nft_id,$nft_name" >> $appdir/$outfile
			fi
		done
	fi

	###########################################################
	# Name Generators
	###########################################################
	if [ "$menu_selection" == "7" ]; then
		echo ""
		echo " 1. Droid Name Generator - create list of unique names based on a galaxy far, far away."
		echo " 2. Norby Name Generator - create list of names in this pattern: AAAA-9999. Can allow duplicates or force to be unique."
		echo " 3. Random Name Picker - select 1 or 2 word names from text files. Allow duplicates or force unique names."
		echo ""
		read -p " Selection? " submenu_select

		if [ "$submenu_select" == "1" ]; then
			echo " Droid Name Generator"
			echo ""
			read -p " How many names to create? " num

			for (( c=0; c<$num; c++ ))
			do
				# let make sure each name is unique, so loop until we create a new one
				available=0
				until [[ "$available" -eq "1" ]]; do

					alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
					name=""

					case $(( RANDOM % 100 )) in
						0|99)
							# 0-0-0 style, weight: 2%
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name$[($RANDOM % 10)]" ;;

						1|30|50|70|98)
							# R-3X style, weight: 5%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						12|22|42|62|82|92)
							# EV-9D9 style, weight: 6%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name$[($RANDOM % 10)]" ;;

						6|26|56|76|86|96)
							# C1-10P style, weight: 6%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name$[($RANDOM % 10)]"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						7|17|27|67|77|87|97)
							# MSE-6 style, weight: 7%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]" ;;

						31|32|35|36|37|38|39)
							# L3-37 style, weight: 7%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name$[($RANDOM % 10)]" ;;

						40|41|45|46|47|49|94)
							# 2-1B style, weight: 7%
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						15|52|57|61|89)
							# D-O style, weight: 5%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						5|25|55|65|85|90|91|95)
							# AP-5 style, weight: 8%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]" ;;

						9|11|20|54|69|71|72|81)
							# IG-11 style, weight: 8%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name$[($RANDOM % 10)]" ;;

						4|14|24|34|44|64|74|84)
							# 4-LOM style, weight: 8%
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						8|18|28|29|48|58|68|78|88)
							# BB-8 style, weight: 9%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]" ;;

						3|10|13|23|33|43|53|63|73|83|93)
							# C-3PO style, weight: 10%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name-"
							name="$name$[($RANDOM % 10)]"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}" ;;

						2|16|19|21|51|59|60|66|75|79|80)
							# R2-D2 style, weight: 10%
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name$[($RANDOM % 10)]"
							name="$name-"
							name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
							name="$name$[($RANDOM % 10)]" ;;
					esac

					if [[ ! " ${used[*]} " =~ " ${name} " ]]; then
						available=1
					fi
				done
				used+=("$name")
				echo -e "${txtrst}$name${bldgrn}"
			done
		fi

		if [ "$submenu_select" == "2" ]; then
			echo " Norby Name Generator"
			echo ""
			read -p " How many names to create? " num

			for (( c=0; c<$num; c++ ))
			do
				# let make sure each name is unique, so loop until we create a new one
				available=0
				until [[ "$available" -eq "1" ]]; do

					alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
					name=""

					#first the alphas
					name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
					name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
					name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"
					name="$name${alphabet:$((RANDOM % ${#alphabet})):1}"

					name="$name-"

					#then the digits
					name="$name$[($RANDOM % 10)]"
					name="$name$[($RANDOM % 10)]"
					name="$name$[($RANDOM % 10)]"
					name="$name$[($RANDOM % 10)]"

					if [[ ! " ${used[*]} " =~ " ${name} " ]]; then
						available=1
					fi
				done
				used+=("$name")
				echo -e "${txtrst}$name${bldgrn}"
			done
		fi

		if [ "$submenu_select" == "3" ]; then

			infile1=""
			infile2=""
			file1=""
			file2=""
			unique=0
			num=0

			echo " Random Name Picker"
			echo ""
			read -p " How many names to create? " num
			echo ""
			read -p " How many words 1 or 2? " words
			echo ""
			read -p " Unique Y/N? " unique

			if [ "$unique" == "Y" ] || [ "$unique" == "y" ]; then
				unique=1
			fi

			if [ "$words" == "1" ] || [ "$words" == "2" ]; then
				echo " Be sure you don't have blank lines in the file or those will be counted as possibles values."
				echo ""
				read -p " First word filename? " infile1
				if [ "$words" == "2" ]; then
					echo ""
					read -p " Second word filename? " infile2
				fi

				# Import name file
				# Sort and print the name arrays to verify you don't have repeats
				# Get Number of records in files
				if [[ -f "$infile1" ]]; then
					name1=`cat $infile1`
					one=( $( for x in ${name1[@]}; do echo $x; done | sort) )
					file1count=`cat $infile1 | wc -l` && file1count=$(($file1count-1))
				else
					echo " ERROR: Could not find file to use for names."
					exit 1
				fi
				if [[ -f "$infile2" ]]; then
					name2=`cat $infile2`
					two=( $( for x in ${name2[@]}; do echo $x; done | sort) )
					file2count=`cat $infile2 | wc -l` && file2count=$(($file2count-1))
				fi

				# loop through each file and create metadata file
				for (( itm=1; itm<=$num; itm++ ))
				do
					if [[ "$unique" -eq "1" ]]; then

						# MUST BE UNIQUE NAMES
						# generate a new name until we have one that isn't already used.
						available=0
						until [[ "$available" -eq "1" ]]; do

							if [[ -f "$infile2" ]]; then
								a=`shuf -i 0-$file1count -n1`
								b=`shuf -i 0-$file2count -n1`
								myname="${one[a]} ${two[b]}"
							else
								a=`shuf -i 0-$file1count -n1`
								myname="${one[a]}"
							fi

							if [[ ! " ${used_names[*]} " =~ " ${myname} " ]]; then
								available=1
							fi
						done
						used_names+=( "$myname" )
						echo -e "${txtrst}$myname${bldgrn}"

						else

							# REPEATS are okay
							if [[ -f "$infile2" ]]; then
								a=`shuf -i 0-$file1count -n1`
								b=`shuf -i 0-$file2count -n1`
								myname="${one[a]} ${two[b]}"
							else
								a=`shuf -i 0-$file1count -n1`
								myname="${one[a]}"
						fi
						echo -e "${txtrst}$myname${bldgrn}"
					fi
				done
			fi
		fi
	fi

	###############################################################
	# Randomly Select an NFT from All or by Wallet ID or Collection
	###############################################################
	if [ "$menu_selection" == "8" ]; then
		echo ""
		echo " 1. Randomly select one from all my NFTs"
		echo " 2. Randomly select one from a specific Wallet ID"
		echo " 3. Randomly select one from a specific Collection"
		echo ""
		read -p " Selection? " random_type

		# One from all my NFTs
		if [ "$random_type" == "1" ]; then

			full_nft_list=""

			# get a list of nft wallet ids
			wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
			c=1

			for val in $wallet_list; do
				nft_id_list=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`
				full_nft_list=$(echo -e "$full_nft_list\n$nft_id_list")
				c=$(($c+1))
			done
			echo "$full_nft_list" > $appdir/files/.full_list

			# using sed to remove any blank lines from the file so our nft count will be correct.
			sed -i '/^$/d' $appdir/files/.full_list

			full_list=`cat $appdir/files/.full_list`
			nft_list=( $( for x in ${full_list[@]}; do echo $x; done | sort) )
			nft_count=`cat $appdir/files/.full_list | wc -l`
			echo ""
			echo -e " Total all NFTs: ${txtrst}$nft_count${bldgrn}"
			echo ""
			nft_count=$(($nft_count-1))
			random_index=`shuf -i 0-$nft_count -n1`
			nft_id="${nft_list[random_index]}"
			nft_wallet_id=$(get_wallet_id $nft_id)
			nft_details $nft_id $nft_wallet_id

			echo ""
			read -p " Airdrop Y/N? " airdrop

			if [ "$airdrop" == "Y" ] || [ "$airdrop" == "y" ]; then
				send_nft $nft_id "false"
			fi
		fi

		# One from a specific Wallet ID
		if [ "$random_type" == "2" ]; then
			echo ""
			wallet_id_list=""
			# get a list of nft wallet ids
			wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
			echo -e " Wallet IDs: ${txtrst}$wallet_list${bldgrn}"
			echo ""
			read -p " Chosen Wallet ID? " wallet_id
			wallet_id_list=`chia wallet nft list -i $wallet_id | grep "NFT identifier" | cut -c 28-`
			echo "$wallet_id_list" | tr ' ' '\n' > $appdir/files/.wid_$wallet_id
			wid_list=`cat $appdir/files/.wid_$wallet_id`
			nft_list=( $( for x in ${wid_list[@]}; do echo $x; done | sort) )
			nft_count=`cat $appdir/files/.wid_$wallet_id | wc -l`
			echo ""
			echo -e " Total all NFTs: ${txtrst}$nft_count${bldgrn}"
			nft_count=$(($nft_count-1))
			random_index=`shuf -i 0-$nft_count -n1`
			nft_id="${nft_list[random_index]}"
			echo ""
			nft_wallet_id=$(get_wallet_id $nft_id)
			nft_details $nft_id $nft_wallet_id

			echo ""
			read -p " Airdrop Y/N? " airdrop

			if [ "$airdrop" == "Y" ] || [ "$airdrop" == "y" ]; then
				send_nft $nft_id "false"
			fi
		fi

		# One from a specific Collection
		if [ "$random_type" == "3" ]; then
			echo ""
			read -p " Collection ID? " collection_id

			official_collection_ids=`curl -s "https://api.mintgarden.io/collections/$collection_id/nfts/ids" | jq '.[].encoded_id' | cut --fields 2 --delimiter=\"`

			collection_list=""
			full_list=""

			# get a list of nft wallet ids
			wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
			c=1
			for val in $wallet_list; do
				nft_id_list=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`
				for id in $nft_id_list; do
					for oc_id in $official_collection_ids; do
						if [ "$id" == "$oc_id" ]; then
							collection_list="$collection_list $id"
						fi
					done
				done
				c=$(($c+1))
			done
			collection_list=`echo $collection_list | tr ' ' '\n'`

			echo "$collection_list" | tr ' ' '\n' > $appdir/files/.$collection_id

			my_list=`cat $appdir/files/.$collection_id`
			nft_list=( $( for x in ${my_list[@]}; do echo $x; done | sort) )
			nft_count=`cat $appdir/files/.$collection_id | wc -l`
			echo ""
			echo -e " Total my NFTs in Collection: ${txtrst}$nft_count${bldgrn}"
			nft_count=$(($nft_count-1))
			random_index=`shuf -i 0-$nft_count -n1`
			nft_id="${nft_list[random_index]}"
			echo ""
			nft_wallet_id=$(get_wallet_id $nft_id)
			nft_details $nft_id $nft_wallet_id

			echo ""
			read -p " Airdrop Y/N? " airdrop

			if [ "$airdrop" == "Y" ] || [ "$airdrop" == "y" ]; then
				send_nft $nft_id "false"
			fi
		fi
	fi

	###########################################################
	# Batch Move NFTs to Profile/DID
	###########################################################
	if [ "$menu_selection" == "9" ]; then
		echo ""
		echo -e " 1. Single NFT ID"
		echo -e " 2. File of NFT IDs"
		echo ""
		read -p " Selection? " submenu_select
		echo ""
		my_dids=$(get_my_dids)
		fingerprint=$(get_fingerprint)

		# get fee to send in mojos
		fee_mojos=""
		read -p " [Enter] for 1 mojo fee, or specific number of mojos: " fee_mojos
		if [ "$fee_mojos" == "" ]; then
			fee_mojos="1"
		fi
		echo ""

		# convert fee_mojos to fee_xch
		fee_xch=$(mojo2xch $fee_mojos)

		if [ "$submenu_select" == "1" ]; then
			read -p " NFT ID? " nft_id
			echo -e ""
			echo -e " DIDs: "
			echo -e "${txtrst}$my_dids${bldgrn}"
			echo -e ""
			read -p " DID ID? " did_id

			nft_wallet_id=$(get_wallet_id $nft_id)
			nft_coin_id=$(get_nft_coin_id $nft_id)
			echo ""
			unfinished_txs="unknown"
			while [[ -n $unfinished_txs ]]
			do
				unfinished_txs=`chia wallet get_transactions -f $fingerprint -l 5 --sort-by-height | grep -E 'Unconfirmed|Pending'`
				if [[ -n $unfinished_txs ]]; then
					printf "%s\n" "$unfinished_txs"
					sleep_countdown 20
					continue
				else
					printf "TXs clear, moving NFT...\n"
					break
				fi
			done

			cmd="~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch"
			echo " COMMAND"
			echo -e " ${txtrst}$cmd${bldgrn}"
			echo ""
			read -p " Run command Y/N? " run
			if [ "$run" == "Y" ] || [ "$run" == "y" ]; then
				~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch
			fi
		else
			my_dids=$(get_my_dids)
			fingerprint=$(get_fingerprint)

			echo -e " 1. All to one DID"
			echo -e " 2. Each line in file will include DID"
			echo ""
			read -p " Selection? " method
			echo ""

			if [ "$method" == "1" ]; then
				echo -e " DIDs: "
				echo -e "${txtrst}$my_dids${bldgrn}"
				echo -e ""
				read -p " DID ID? " did_id
				echo -e ""
				echo -e " File structure should be one NFT ID per line. Ensure file does not have blank lines."
				echo -e ""
			fi
			if [ "$method" == "2" ]; then
				echo -e " File structure should be CSV in format of:  NFT_ID,DID_ID"
				echo -e ""
				echo -e " Example:"
				echo -e "${txtrst} nft1hkmtytdwcs6n25ntq82s6mjslh4h09tdj994scle2fzw93nwxu7qzhvy2g,did:chia:1lwf5wtluvc5flp2ht46xprwvadyykjsctjcgyl3ffktzmd3d4r9slupmsq${bldgrn}"
				echo -e ""
				echo -e " Ensure the file does not have blank lines."
				echo -e ""
			fi
			read -p " Filename? " filename

			file_contents=`cat $filename`
			for line in $file_contents; do
				case $method in
					"1")
						nft_id="$line"
						nft_wallet_id=$(get_wallet_id $nft_id)
						nft_coin_id=$(get_nft_coin_id $nft_id)
						echo "Method 1: NFT_ID = $nft_id, DID_ID = $did_id"
						unfinished_txs="unknown"
						while [[ -n $unfinished_txs ]]
						do
							unfinished_txs=`chia wallet get_transactions -f $fingerprint -l 5 --sort-by-height | grep -E 'Unconfirmed|Pending'`
							if [[ -n $unfinished_txs ]]; then
								printf "%s\n" "$unfinished_txs"
								sleep_countdown 20
								continue
							else
								printf "TXs clear, moving NFT...\n"
								break
							fi
						done

						cmd="~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch"
						echo " COMMAND"
						echo -e " ${txtrst}$cmd${bldgrn}"
						echo ""

						~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch
						echo "Waiting on the blockchain..."
						sleep_countdown 120
					;;

					"2")
						nft_id=`echo $line | cut --fields 1 --delimiter=,`
						did_id=`echo $line | cut --fields 2 --delimiter=,`
						nft_wallet_id=$(get_wallet_id $nft_id)
						nft_coin_id=$(get_nft_coin_id $nft_id)
						echo "Method 2: NFT_ID = $nft_id, DID_ID = $did_id"
						unfinished_txs="unknown"
						while [[ -n $unfinished_txs ]]
						do
							unfinished_txs=`chia wallet get_transactions -f $fingerprint -l 5 --sort-by-height | grep -E 'Unconfirmed|Pending'`
							if [[ -n $unfinished_txs ]]; then
								printf "%s\n" "$unfinished_txs"
								sleep_countdown 20
								continue
							else
								printf "TXs clear, moving NFT...\n"
								break
							fi
						done

						cmd="~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch"
						echo " COMMAND"
						echo -e " ${txtrst}$cmd${bldgrn}"
						echo ""

						~/chia-blockchain/venv/bin/chia wallet nft set_did -f $fingerprint -i $nft_wallet_id -di $did_id -ni $nft_coin_id -m $fee_xch
						echo "Waiting on the blockchain..."
						sleep_countdown 120
					;;
				esac

			done
		fi
	fi

	echo ""
	read -p " Press [Enter] to continue... " keypress

}

###########################################################
# MAIN
###########################################################
while true
do
	clear
	display_banner
	menu
done

# set colors back to normal
echo -e "${txtrst}"

#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# END
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


# Version 0.4
# Big refactor. Functions, parameters, returns, and variables were a mess and needed to be cleaned up.
# Added Random Picker for NFT by 1) all my NFTs, 2) a specific Wallet ID, and 3) a specific Collection ID.
# Added Batch Move NFT to Profile option. Thanks to @scotopic for idea & sample code.
#
# Version 0.3
# Code refactor to remove unnecessary outside tools. Such as xargs and rev
# Added install script
# Updated README.md with istall instructions and new screenshots. Added credit to Mintgarden API
#
# Version 0.2
# Added action to get list of "my NFT IDs"
# Added action to get list of NFT IDs from Collection
# Added action to get list of Owner Wallets from NFT IDs
# Added action to get list of NFT Names from NFT IDs
# Added action for Name Generator - Droid name generator
# Added action for Name Generator - Norby name generator
# Added action for Name Generator - Random name picker
#
# Version 0.1
# Initial version. Basic functionality.
# View NFT Info
# Send/Transfer NFT
# README.md file with screenshots

