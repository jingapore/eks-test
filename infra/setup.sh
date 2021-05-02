echo 'What is the AWS_PROFILE that you are using?'
read AWS_PROFILE_TO_SET

export AWS_PROFILE=${AWS_PROFILE_TO_SET}
echo -e '\nHave set AWS_PROFILE in bash session.n'

for DIRECTORYNAME in */
    do
    echo -e "\ngoing thru directory '${DIRECTORYNAME}'..."
    for FILENAME in `ls ./${DIRECTORYNAME} | egrep -o '.+\.tfvars' | sed -e "s!^!.\/${DIRECTORYNAME}!"`
        do 
        echo "replacing value of a single mention of 'aws_profile' in '${FILENAME}'"
        # annotation for sed command:
        # \1 following by \"${AWS_PROFILE_TO_SET}" replaces line with first capturing group
        # then everything after that is replaced by AWS_PROFILE
        # https://unix.stackexchange.com/questions/90653/why-do-i-need-to-escape-regex-characters-in-sed-to-be-interpreted-as-regex-chara
        # https://unix.stackexchange.com/questions/165589/replace-regex-capture-group-content-using-sed
        sed -i --regexp-extended "s/^(aws_profile = )(..*)$/\1\"${AWS_PROFILE_TO_SET}\"/" "${FILENAME}"
        done
    done

echo -e '\nHave changed all mentions of aws_profile in .tf files to AWS_PROFILE'