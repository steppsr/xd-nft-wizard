#!/bin/bash

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

display_banner() {
version="0.3"
echo -e "${bldgrn}"
echo -e "          _          __ _              _                  _ "
echo -e "         | |        / _| |            (_)                | |"
echo -e " __  ____| |  _ __ | |_| |_  __      ___ ______ _ _ __ __| |"
echo -e " \ \/ / _' | | '_ \|  _| __| \ \ /\ / / |_  / _' | '__/ _' |"
echo -e "  >  < (_| | | | | | | | |_   \ V  V /| |/ / (_| | | | (_| |"
echo -e " /_/\_\__,_| |_| |_|_|  \__|   \_/\_/ |_/___\__,_|_|  \__,_|"
echo -e "------------------------------------------------------------${txtred}"
echo -e "Interactive script to help with NFT tasks.       version $version${bldgrn}"
echo -e "------------------------------------------------------------"
}

mojo2xch () {
    local mojo=$fee_mojos
    xch=""

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
}

get_wallet_id () {
   local nid=$nft_id

   # get a list of nft wallet ids
   wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`

   # search for wallet id containing nft id
   nft_wallet_id=""
   for val in $wallet_list; do
      found="false"
      nft_id_list=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`
      for id in $nft_id_list; do
         if [ "$id" == "$nft_id" ]; then
            nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
            nft_coin_id=`echo "$nft_json" | jq '.id' | cut --fields 2 --delimiter=\"`
            nft_collection=`echo "$nft_json" | jq '.data.metadata_json.collection.name' | cut --fields 2 --delimiter=\"`
            nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
            echo -e "NFT ID:         ${txtrst}$id${txtgrn}"
            echo -e "NFT Collection: ${txtrst}$nft_collection${txtgrn}"
            echo -e "NFT Name:       ${txtrst}$nft_name${txtgrn}"
            echo -e "NFT Coin ID:    ${txtrst}$nft_coin_id${txtgrn}"
            echo -e "Wallet ID:      ${txtrst}$val${txtgrn}"
            echo ""
            read -p "Is this correct Y/N? " is_correct
            if [ "$is_correct" == "Y" ] || [ "$is_correct" == "y" ]; then
               nft_wallet_id="$val"
               found="true"
               break
            fi
         fi
      done
      if [ "$found" == "true" ]; then
         break
      fi
   done
}

get_fingerprint () {
   fingerprint=`chia wallet show | grep "fingerprint" | cut -c 24-`
}

menu() {
echo ""
echo " 1. View NFT details by NFT ID"
echo " 2. Send NFT to Wallet Address"
echo " 3. Get list of my NFTs"
echo " 4. Get list of NFT IDs from Collection"
echo " 5. Get list of Owner Wallets from NFT IDs"
echo " 6. Get list of NFT Names from NFT IDs"
echo " 7. Name generators"
echo " x. Exit"
echo ""
read -p "Selection: " menu_selection

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
   read -p "NFT ID? " nft_id
   echo -e "Searching for ${txtrst}$nft_id${bldgrn}..."
   echo ""

   get_wallet_id && found=$found && wallet_id=$nft_wallet_id

   if [ "$found" == "false" ]; then
      echo ""
      echo "Could not find that NFT ID in your wallet."
   fi
fi

###########################################################
# Send NFT to Wallet Address
###########################################################
if [ "$menu_selection" == "2" ]; then
   echo ""
   read -p "NFT ID? " nft_id
   echo -e "Searching for ${txtrst}$nft_id${bldgrn} ..."
   echo ""

   get_wallet_id && found=$found && wallet_id=$wallet_id

   if [ "$found" == "false" ]; then
      echo "Could not find that NFT ID in your wallet."
   else
      # get coin id from nft id
      coin_id=`chia wallet nft get_info -ni $nft_id | grep "Current NFT coin ID" | cut -c 28-`
      echo ""
      read -p "Destination address? " destination
      echo ""
      fee_mojos=""
      read -p "[Enter] for 1 mojo fee, or specific number of mojos: " fee_mojos
      if [ "$fee_mojos" == "" ]; then
         fee_mojos="1"
      fi
      echo ""

      # convert fee_mojos to fee_xch
      mojo2xch && fee_xch=$xch

      # get the current fingerprint
      get_fingerprint && fingerprint=$fingerprint

      # transfer nft
      cmd="~/chia-blockchain/venv/bin/chia wallet nft transfer -f $fingerprint -i $nft_wallet_id -m $fee_xch -ni $coin_id -ta $destination"
      echo "COMMAND"
      echo -e "${txtrst}$cmd${bldgrn}"

      echo ""
      read -p "Run command Y/N? " run
      if [ "$run" == "Y" ] || [ "$run" == "y" ]; then
         ~/chia-blockchain/venv/bin/chia wallet nft transfer -f $fingerprint -i $nft_wallet_id -m $fee_xch -ni $coin_id -ta $destination
      fi
   fi
fi

###########################################################
# Create a list of my NFTs
###########################################################
if [ "$menu_selection" == "3" ]; then
   echo ""
   wallet_list=`chia wallet show -w nft | grep "Wallet ID" | cut -c 28- | tr '\n' ' '`
   echo -e "NFT Wallets: ${txtrst}$wallet_list${bldgrn}"
   echo ""
   read -p "Wallet ID, or [Enter] for all, or [x] to cancel? " answer_wallet

   if [ "$answer_wallet" != "X" ] && [ "$answer_wallet" != "x" ]; then

	   if [ "$answer_wallet" != "" ]; then
	      wallet_list="$answer_wallet"
	   fi

	   all=0
	   for val in $wallet_list; do

	      echo ""
	      echo "==== Wallet ID: $val ===="

	      c=`chia wallet nft list -i $val | grep "NFT identifier" | wc -l`
	      nft_ids=`chia wallet nft list -i $val | grep "NFT identifier" | cut -c 28-`

	      for id in $nft_ids; do
	         nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
	         nft_collection=`echo "$nft_json" | jq '.data.metadata_json.collection.name' | cut --fields 2 --delimiter=\"`
	         nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut --fields 2 --delimiter=\"`
	         echo -e "${txtrst}$id [$nft_collection] $nft_name${bldgrn}"
	      done

	      echo -e "Wallet Total: ${txtrst}$c${bldgrn}"
	      all=$(($all+$c))

	   done

		echo ""
		echo -e "Total number of NFTs: ${txtrst}$all${bldgrn}"
    fi
fi

###########################################################
# Get list of NFT IDs from Collection
###########################################################
if [ "$menu_selection" == "4" ]; then
   echo ""
   echo -e "You will need the Collection ID. You can find this on    ${txtrst}https://mintgarden.io${bldgrn}"
   echo -e ""
   echo -e "Search for your collection name ie. BattleKats which should result in a page with a URL like such:"
   echo -e "   ${txtrst}https://mintgarden.io/collections/battlekats-col1kmrzafjx6ej8w79tz5vnjt4w8xuq2p6nmnheelgwwu3rsgsar0fsxc4wud${bldgrn}"
   echo -e ""
   echo -e "You Collection ID is everything after the hyphen in the URL."
   echo -e "For example:   ${txtrst}col1kmrzafjx6ej8w79tz5vnjt4w8xuq2p6nmnheelgwwu3rsgsar0fsxc4wud${bldgrn}"
   echo -e ""
   read -p "Collection ID? " collection_id
   if [ "$collection_id" != "X" ] && [ "$collection_id" != "x" ]; then
	   nfts=`curl -s https://api.mintgarden.io/collections/$collection_id/nfts/ids`
	   echo -e "${txtrst}"
	   echo "$nfts" | jq '.[].encoded_id' | cut --fields 2 --delimiter=\"
	   echo -e "${txtgrn}"
   fi
fi

###########################################################
# Get list of Owner Wallets from NFT IDs
###########################################################
if [ "$menu_selection" == "5" ]; then
   echo ""
   echo "1. Single NFT ID"
   echo "2. File of NFT IDs"
   read -p "Selection? " submenu_select
   if [ "$submenu_select" == "1" ]; then
      echo ""
      read -p "NFT ID? " nft_ids
   else
      echo ""
      read -p "Filename? " filename
      nft_ids=`cat $filename`
   fi
   echo ""
   read -p "Output to Screen or File S/F? " output_type
   if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
      read -p "Filename to save as? " outfile
      if [ -f "$outfile" ]; then
         rm $outfile
         touch $outfile
      fi
   fi

   n=1
   for id in $nft_ids; do
      nft_json=`curl -s https://api.mintgarden.io/nfts/$id`
      nft_id=`echo "$nft_json" | jq '.encoded_id' | cut --fields 2 delimiter=\"`
      nft_owner_wallet=`echo "$nft_json" | jq '.owner_address.encoded_id' | cut --fields 2 --delimiter=\"`
      #outputting to the console screen slows the script down
      if [ "$output_type" == "S" ] || [ "$output_type" == "s" ]; then
         echo -e "${txtrst}$n. $id $nft_owner_wallet${bldgrn}"
      fi
      if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
         echo "$nft_owner_wallet" >> $appdir/$outfile
      fi
      n=$(($n+1))
   done
fi

###########################################################
# Get list of NFT Names from NFT IDs"
###########################################################
if [ "$menu_selection" == "6" ]; then
   echo ""
   echo "1. Single NFT ID"
   echo "2. File of NFT IDs"
   read -p "Selection? " submenu_select
   if [ "$submenu_select" == "1" ]; then
      echo ""
      read -p "NFT ID? " nft_ids
   else
      echo ""
      read -p "Filename? " filename
      nft_ids=`cat $filename`
   fi
   echo ""
   read -p "Output to Screen or File S/F? " output_type
   if [ "$output_type" == "F" ] || [ "$output_type" == "f" ]; then
      read -p "Filename to save as? " outfile
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
# menu item comment
###########################################################
if [ "$menu_selection" == "7" ]; then
   echo ""
   echo "1. Droid Name Generator - create list of unique names based on a galaxy far, far away."
   echo "2. Norby Name Generator - create list of names in this pattern: AAAA-9999. Can allow duplicates or force to be unique."
   echo "3. Random Name Picker - select 1 or 2 word names from text files. Allow duplicates or force unique names."
   echo ""
   read -p "Selection? " submenu_select

	if [ "$submenu_select" == "1" ]; then
		echo "Droid Name Generator"
		echo ""
		read -p "How many names to create? " num

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
			echo $name
		done
	fi

	if [ "$submenu_select" == "2" ]; then
		echo "Norby Name Generator"
		echo ""
		read -p "How many names to create? " num

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
		echo $name
		done
	fi

	if [ "$submenu_select" == "3" ]; then

		infile1=""
		infile2=""
		file1=""
		file2=""
		unique=0
		num=0

		echo "Random Name Picker"
		echo ""
		read -p "How many names to create? " num
		echo ""
		read -p "How many words 1 or 2? " words
		echo ""
		read -p "Unique Y/N? " unique

		if [ "$unique" == "Y" ] || [ "$unique" == "y" ]; then
			unique=1
		fi

		if [ "$words" == "1" ] || [ "$words" == "2" ]; then
            echo "Be sure you don't have blank lines in the file or those will be counted as possibles values."
            echo ""
		    read -p "First word filename? " infile1
			if [ "$words" == "2" ]; then
                echo ""
				read -p "Second word filename? " infile2
			fi

			# Import name file
			# Sort and print the name arrays to verify you don't have repeats
			# Get Number of records in files
			if [[ -f "$infile1" ]]; then
				name1=`cat $infile1`
				one=( $( for x in ${name1[@]}; do echo $x; done | sort) )
				file1count=`cat $infile1 | wc -l` && file1count=$(($file1count-1))
			else
				echo "ERROR: Could not find file to use for names."
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

echo ""
read -p "Press [Enter] to continue... " keypress

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
