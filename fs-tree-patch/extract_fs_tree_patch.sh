#!/bin/bash

A_TREE=$1
B_TREE=$2
PATCH_DIR=$3

# Generate the patch filesystem tree index file.
# This file will contain the symlinks dereference as well in the following form:
# path/to/symlink -> path/to/the/file/its/pointing
rsync -avun $B_TREE $A_TREE --exclude=/var/log --exclude=/root --exclude=/var/cache | \
        sed -n -e "2,$ p" | \
        head -n -3 > .work_symlinks_paths.txt

# Refresh the "symlink-free" file
rm -f .work_no_symlinks_paths.txt
touch .work_no_symlinks_paths.txt

# Get rid of symlink dereference in the index
while read line; do 
        if [[ $line == *"->"* ]]; then
                in=(${line//->/ })
                line=${in[0]}
        fi
        echo "${line}" >> .work_no_symlinks_paths.txt
done < .work_symlinks_paths.txt

# Create the directory for the patch filesystem tree
mkdir -p $PATCH_DIR

# Now copy all files listed in the index generated
while read line; do 
        if [[ -d $B_TREE/$line ]]; then
                mkdir -p $PATCH_DIR/$line
        else
                dir=$PATCH_DIR/${line%/*}
                if [ ! -d $dir ]; then
                        echo "mkdir -p $dir"
                        mkdir -p $dir
                fi
                cp -dr "${B_TREE}/${line}" "${PATCH_DIR}/${line}"
        fi
done < .work_no_symlinks_paths.txt

rm -f .work_symlinks_paths.txt
rm -f .work_no_symlinks_paths.txt
