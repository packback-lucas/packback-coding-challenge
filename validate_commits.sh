valid_commit_prefix () {
  MESSAGE=$1
  REGEX="^(PODA|PODB|PODC|MGMT)-(\d+)*"
  if [[ $MESSAGE =~ $REGEX ]]
  then
    echo 1
  else
    echo 0
  fi
}

RESPONSE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/packbackbooks/code-challenge-devops/commits)

LINES=$(echo $RESPONSE | sed 's/\\n/ /g' | jq -r ".[] | .commit.message, .author.login, .sha")

while read -r MESSAGE; do
  read -r AUTHOR
  read -r SHA
  IS_VALID=$(valid_commit_prefix "$MESSAGE")
  if [[ $IS_VALID == 1 ]]
  then
    IS_VALID="TRUE"
  else
    IS_VALID="FALSE"
  fi
  echo "$SHA $IS_VALID $AUTHOR"

done <<< "$LINES"
