# xd-nft-wizard
xd nft wizard is a interactive Bash script to help with Chia NFTs. 

## Requiements
You may need to install the following tools if you don't already have them. Run `which toolname` from the 
command line, where toolname is one of the tools below to see if there is one installed on your machine. If
the command returns a path, then you have the tool. If it does not, then you may need to install the tool.

**Required tools:**
1. curl
2. jq
3. xargs
4. rev
5. grep
6. cut
7. wc

## Running the command
Use the `bash` command to run the script. You can also use redirect to send the output to a file.

Example:
```
bash xdnft.sh

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

## Screenshot
![xd nft wizard](https://xchdev.com/images/xd-nft-wizard.png)

![xd nft wizard](https://xchdev.com/images/xd-nft-wizard-2.png)
