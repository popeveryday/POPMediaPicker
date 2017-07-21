echo "Enter next submit comment"
read answer

echo "Allow warning? (y/[n])"
read alw


if [ "$answer" == '' ] ; 
then
    echo "nothing"
else
	git add -A && git commit -m $answer
	git push origin master
	git tag $answer
	git push --tag
	
	folder=${PWD##*/} 

	if [ "$alw" == 'y' ] ; 
	then
	    pod trunk push $folder.podspec --allow-warnings
	else
		pod trunk push $folder.podspec
	fi
fi




