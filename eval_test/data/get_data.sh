cat $1 | grep "econd\|Minute" > save_data.txt
sed -n 'N;N;s/\n/ /g;p' save_data.txt | awk '{print ($2 * 60000) + ($4 * 1000) + $6}' > real_data.txt

