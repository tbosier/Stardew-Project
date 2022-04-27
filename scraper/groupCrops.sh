#!/bin/bash

crops=crops.html
cropGroups=cropGroups.txt

# Get Sell Price foreach Crop
# $1: crop name
getSellPrice()
{
	sellPriceRegex="$1\.png 2x.*\"qualityindicator\"><\/div"
	cropName=$(sed 's/_/ /g' <<< $1)
	cat $crops | grep -E -A 2 "$sellPriceRegex" | grep -A 2 $cropName | tail -n 1 | sed -E 's/<td>(.*)g/\1/g'
}

#$1: store name
#$2: string
getSeedPrice()
{
	if [[ $(echo $2 | sed -E "s/.*($1).*/\1/") == $1 ]]; then
		echo $2 | sed -E "s/($1.*\/span).*/\1/" | sed -E "s/<\/span.*//" | sed -E "s/.*>([0-9,]*)g/\1/g"
	fi

}

# $1: crop name
getSeedPrices()
{
	seedOffset=26
	seedFinderRegex="$1\">$1<\/a></span></h3>"
	expectedSeedLine=$(cat $crops | grep -E -A $((seedOffset)) "$seedFinderRegex" | tail -n 1)
	if [[ $expectedSeedLine == "<tr>" ]]; then
		seedOffset=$((seedOffset + 2))
	elif [[ $expectedSeedLine == "</td>" ]]; then
		seedOffset=$((seedOffset - 1 ))
	else
		: # expected case, do nothing
	fi
	s=$(cat $crops | grep -E -A $((seedOffset)) "$seedFinderRegex" | tail -n 1)
	IFS="!"
#	echo "$(getSeedPrice "Pierre" ${s})"
	echo "$(getSeedPrice "Pierre" $s),$(getSeedPrice "Joja" $s),$(getSeedPrice "Oasis" $s),$(getSeedPrice "Egg" $s)"
#
#	echo "offset is $((seedOffset))"
}

#Get Crop Groups
cropGroupRgx="<li class=\"toclevel-1.* tocsection-[0-9]*\>.*>(.*) Crops<.*a>$"
grep -E -n "$cropGroupRgx" $crops | sed -E "s/$cropGroupRgx/\1/g" > cropGroupsTmp.txt
:> $cropGroups
while read line; do
	echo $line | cat - $cropGroups > temp && mv temp $cropGroups
done <cropGroupsTmp.txt
rm cropGroupsTmp.txt

# Get Crops in each group
cropItemRgx="<li class=\"toclevel-2.*\"toctext\">([ a-zA-Z]*)<.*li>$"
grep -E -n "$cropItemRgx" $crops | sed -E "s/$cropItemRgx/\1/g" > cropItems.txt

echo 'crop,season,sellPrice,pierre,joja,oasis,egg'
while read cropPair; do
	cropLine=$(echo -n $cropPair | cut -d ':' -f 1)
	cropName=$(echo -n $cropPair | cut -d ':' -f 2)
	while read cropGroupPair; do
		groupLine=$(echo -n $cropGroupPair | cut -d ':' -f 1)
		groupName=$(echo -n $cropGroupPair | cut -d ':' -f 2)
		if [[ $groupLine < $cropLine ]]; then
			sellPrice=$(getSellPrice ${cropName})
			seedPrices=$(getSeedPrices ${cropName})
			if [[ $sellPrice != "" ]]; then
				echo "$cropName,$groupName,$sellPrice,$seedPrices"
			fi
			break
		fi
	done <cropGroups.txt
done <cropItems.txt
echo ''

# Get Seed Prices



