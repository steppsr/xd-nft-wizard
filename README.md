# xd-nft-wizard
xd nft wizard is a interactive Bash script to help with Chia NFTs. 

## Download
You can download the following files individually, or grab the latest release. Put the files into
a folder you create for the application. I like to do this in my home directory.

To create a folder for the application in your home directory:
```
cd
mkdir xdnft
```

## Install
There are a couple of require utilities that will be installed if not already on your system.
1. curl
2. jq

To run the install:
```
bash install.sh
```

Follow any on screen prompts. It will ask you to reload your user profile after it completes:
```
source ~/.bashrc
```

## Running the command
```
xdnft
```

## Actions available
1. View NFT details by NFT ID - this will use the given NFT ID to find and display the Wallet ID,
   NFT Collection Name, NFT Name, and the NFT Coin ID.

2. Send NFT to Wallet Address - this will use the given NFT ID and Destination Address and generate
   the command to run to send the NFT. You will also be asked if you wish to run the command.

3. Get list of my NFTs

4. Get list of NFT IDs from Collection

5. Get list of Owner Wallets from NFT IDs

6. Get list of NFT Names from NFT IDs

7. Name generators
   A. Droid Name Generator
   B. Norby Name Generator
   C. Random Name Picker

## Screenshots

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard_1.png)

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard_2.png)

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard_3.png)

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard_4.png)

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard_5.png)
