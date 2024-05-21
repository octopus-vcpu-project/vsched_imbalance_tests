cat $1 | grep "]" | sed 's/\[//g; s/\]//g' | awk '{print $1" "$9}' > new.txt
