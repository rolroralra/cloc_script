#!/bin/bash
USER_NAME=$1
USER_NAME=${USER_NAME:-rolroralra}

INDEX=0
KEY_ARRAY=()
VALUE_ARRAY=()

function cloc-git() {
  git clone --depth 1 $1 temp-linecount-repo >/dev/null 2>&1 &&
  cloc --quiet --yaml temp-linecount-repo &&
  rm -rf temp-linecount-repo
}

function cloc-count-update() {
  OIFS=$IFS
  IFS=$'\n'
  for KEY_WORD in $(cat $1 | yq e 'keys' - | grep -v ^# | grep -v "^- header" | grep -v "^- SUM" | grep -v "^---" | yq e '.[]' -)
  do
    if [[ ${KEY_WORD} == *" "* ]]
    then
      continue
    fi

    COUNT=$(cat $1 | yq e "[.${KEY_WORD}]" - | grep -v ^--- | yq e '[.[] | select (. != null)]' - | yq e '.[] as $item ireduce (0; . + $item.code)' -)

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

for GIT_REPO_URL in $(curl https://api.github.com/users/${USER_NAME}/repos 2>/dev/null | yq e '.[].html_url' -)
do
  echo "[${GIT_REPO_URL}] Checking..."
  cloc-git ${GIT_REPO_URL} > result.yaml &&
  cloc-count-update result.yaml &&
  rm -rf result.yaml
done

echo
cloc-count-print
