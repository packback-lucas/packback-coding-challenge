valid_commit_prefix () {
  MESSAGE=$1
  REGEX="^(PODA|PODB|PODC|MGMT)-([0-9]+)*"
  [[ "$MESSAGE" =~ $REGEX ]]
  if [[ ${BASH_REMATCH[2]} ]]
  then
    echo 1
  else
    echo 0
  fi
}

merged_or_reverted () {
  MESSAGE=$1
  if [[ "$MESSAGE" == *"Merge"* ]] || [[ "$MESSAGE" == *"Revert"* ]]
  then
    echo 1
  else
    echo 0
  fi
}

START_TAG=$1
END_TAG=$2

REGEX="^v1.([0-9]+).0$"

# validate the tag versions
if [[ "$START_TAG" =~ $REGEX ]]
then
  START_MINOR_VERSION="${BASH_REMATCH[1]}"
else
  echo "Invalid start tag $START_TAG"
  exit 1
fi

if [[ "$END_TAG" =~ $REGEX ]]
then
  END_MINOR_VERSION="${BASH_REMATCH[1]}"
else
  echo "Invalid end tag $END_TAG"
  exit 1
fi

if [[ $END_MINOR_VERSION -le $START_MINOR_VERSION ]]
then
  echo "End tag ($END_TAG) must be later than start tag ($START_TAG)"
  exit 1
fi

RESPONSE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/packbackbooks/code-challenge-devops/commits)

LINES=$(echo $RESPONSE | sed 's/\\n/ /g' | jq -r ".[] | .commit.message, .author.login, .sha")

while read -r MESSAGE; do
  read -r AUTHOR
  read -r SHA
  IS_VALID_MESSAGE="FALSE"
  IS_MERGED_OR_REVERTED=$(merged_or_reverted $MESSAGE)
  IS_VALID_PREFIX=$(valid_commit_prefix "$MESSAGE")
  if [[ $IS_VALID_PREFIX == 1 ]] || [[ $IS_MERGED_OR_REVERTED == 1 ]]
  then
    IS_VALID_MESSAGE="TRUE"
  fi
  echo "$SHA $IS_VALID_MESSAGE $AUTHOR $MESSAGE"

done <<< "$LINES"
