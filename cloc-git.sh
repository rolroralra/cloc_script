#!/bin/bash
GIT_REPOSITORY_URL=${1:-"https://github.com/rolroralra/rolroralra"}

INDEX=0
KEY_ARRAY=()
VALUE_ARRAY=()

function cloc-count-update() {
  OIFS=$IFS
  IFS=$'\n'
  for KEY_WORD in $(cat result.yaml | yq e 'keys' - | grep -v ^# | grep -v "^- header" | grep -v "^- SUM" | grep -v "^---" | yq e '.[]' -)
  do
    if [[ ${KEY_WORD} == *" "* ]]
    then
      continue
    fi

    #echo ${KEY_WORD}
    
    COUNT=$(cat result.yaml | yq e "[.${KEY_WORD}]" - | grep -v ^--- | yq e '[.[] | select (. != null)]' - | yq e '.[] as $item ireduce (0; . + $item.code)' -)
    #echo $COUNT

    NEW_KEY_WORD=1
    for (( i=0; i<${#KEY_ARRAY[@]}; i++ ))
    do
      if [[ ${KEY_WORD} == ${KEY_ARRAY[i]} ]]
      then
        NEW_KEY_WORD=0 
        VALUE_ARRAY[$i]=$(( ${VALUE_ARRAY[i]} + ${COUNT} ))
        break
      fi 
    done

    if [[ ${NEW_KEY_WORD} -eq 1 ]]
    then
      KEY_ARRAY+=(${KEY_WORD}) 
      VALUE_ARRAY[${INDEX}]=${COUNT}
      INDEX=$(( ${INDEX} + 1 ))
    fi
  done
  IFS=$OIFS
}

function cloc-count-print() {
  for (( i=0; i<${#KEY_ARRAY[@]}; i++ ))
  do
    echo "${KEY_ARRAY[i]}:${VALUE_ARRAY[i]}"
  done
}


git clone --depth 1 "${GIT_REPOSITORY_URL}" temp-linecount-repo >/dev/null 2>&1 &&
  cloc --quiet --yaml temp-linecount-repo > result.yaml &&
  rm -rf temp-linecount-repo &&
  cloc-count-update result.yaml &&
  rm -f result.yaml &&
  cloc-count-print
