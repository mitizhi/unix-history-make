#!/bin/sh
#
# Analyze unmatched files by adding to each
# the number of lines that were added in the corresponding release

save()
{
	awk '{print $2 " '$1'" }' | sort >$R/sha/$1
}

R=`pwd`

# Create a file with the SHAs belonging to each release
mkdir -p sha
cd import

git rev-list --pretty=format: ^Research-V6 BSD-1 | save BSD-1
git rev-list --pretty=format: ^BSD-1 BSD-2 | save BSD-2
git rev-list --pretty=format: ^BSD-2 ^Bell-32V BSD-3 | save BSD-3
git rev-list --pretty=format: ^Research-V7 Bell-32V | save Bell-32V
git rev-list --pretty=format: ^Research-V1 | save ^Research-V1
git rev-list --pretty=format: ^Research-V1 Research-V3 | save Research-V3
git rev-list --pretty=format: ^Research-V3 Research-V4 | save Research-V4
git rev-list --pretty=format: ^Research-V4 Research-V5 | save Research-V5
git rev-list --pretty=format: ^Research-V5 Research-V6 | save Research-V6
git rev-list --pretty=format: ^Research-V6 Research-V7 | save Research-V7

sort $R/sha/* >$R/sha/all

mkdir -p $R/analyzed

cd $R/unmatched
# For each tag
for T in *
do
	cd $R/import
	git checkout $T
	# For each file not matched
	while read F
	do
		git blame -C -C -s --abbrev=39 $F |
		awk '{print $1}' |
		sort |
		# Join blame SHAs with those associated with releases
		join - $R/sha/all |
		awk '	BEGIN		{t = c = 0}
					{t++}
			$2 == "'$T'"	{c++}
			END {print "'$F'", c, t}'
	done <$R/unmatched/$T |
	sort -k 2nr >$R/analyzed/$T
done
