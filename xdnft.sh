#!/bin/bash

# Activate Chia Environment
appdir=`pwd`
cd ~/chia-blockchain
. ./activate
cd $appdir

display_banner() {
echo ""
echo "          _          __ _              _                  _ "
echo "         | |        / _| |            (_)                | |"
echo " __  ____| |  _ __ | |_| |_  __      ___ ______ _ _ __ __| |"
echo " \ \/ / _' | | '_ \|  _| __| \ \ /\ / / |_  / _' | '__/ _' |"
echo "  >  < (_| | | | | | | | |_   \ V  V /| |/ / (_| | | | (_| |"
echo " /_/\_\__,_| |_| |_|_|  \__|   \_/\_/ |_/___\__,_|_|  \__,_|"
echo "                                                 version 0.1"
echo ""
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
            nft_coin_id=`echo "$nft_json" | jq '.id' | cut -c 2- | rev | cut -c 2- | rev`
            nft_collection=`echo "$nft_json" | jq '.data.metadata_json.collection.name' | cut -c 2- | rev | cut -c 2- | rev`
            nft_name=`echo "$nft_json" | jq '.data.metadata_json.name' | cut -c 2- | rev | cut -c 2- | rev`
            echo "NFT ID:         $id"
            echo "NFT Collection: $nft_collection"
            echo "NFT Name:       $nft_name"
            echo "NFT Coin ID:    $nft_coin_id"
            echo "Wallet ID:      $val"
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
echo " 9. Exit"
echo ""
read -p "Selection: " menu_selection

if [ "$menu_selection" == "9" ]; then
   echo ""
   exit
fi

if [ "$menu_selection" == "1" ]; then
   echo ""
   read -p "NFT ID? " nft_id
   echo "Searching for $nft_id ..."
   echo ""

   get_wallet_id && found=$found && wallet_id=$nft_wallet_id

   if [ "$found" == "false" ]; then
      echo ""
      echo "Could not find that NFT ID in your wallet."
   fi
fi

if [ "$menu_selection" == "2" ]; then
   echo ""
   read -p "NFT ID? " nft_id
   echo "Searching for $nft_id ..."
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
      echo "$cmd"

      read -p "Run command Y/N? " run
      if [ "$run" == "Y" ] || [ "$run" == "y" ]; then
         ~/chia-blockchain/venv/bin/chia wallet nft transfer -f $fingerprint -i $nft_wallet_id -m $fee_xch -ni $coin_id -ta $destination
      fi
   fi
fi

echo ""
read -p "Press [Enter] to continue... " keypress

}

# MAIN
while true
do
   clear
   display_banner
   menu
done
# END
