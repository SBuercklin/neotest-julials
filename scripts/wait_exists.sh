until [ -f $1 ]
do
    sleep 1
done
echo "Found it!"
