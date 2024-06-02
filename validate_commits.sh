#!/usr/bin/env bash

get_commit_sha_from_tag () {
  TAG_VERSION=$1

  TAG_RESPONSE=$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/packbackbooks/code-challenge-devops/git/ref/tags/$TAG_VERSION)

  TAG_SHA=$(echo $TAG_RESPONSE | jq .object.sha | sed 's/"//g')
  TAG_TO_COMMIT_RESPONSE=$(curl -sL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/packbackbooks/code-challenge-devops/git/tags/$TAG_SHA)

  COMMIT_SHA=$(echo $TAG_TO_COMMIT_RESPONSE | jq .object.sha | sed 's/"//g')
  echo $COMMIT_SHA
}

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

if [[ -z "$ACCESS_TOKEN" ]]
then
  echo "Please set a value for the ACCESS_TOKEN environment variable. See README.md"
  exit
fi

START_TAG=$1
END_TAG=$2

# NOTE: This hard-codes the assumptions that the app is ALWAYS on version 1, and
# that patches do not occur.
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

# Now that we have valid start and end tags, we can translate these
# into start and end commits, and filter out the relevant parts of the
# commit history based on these
START_COMMIT_SHA=$(get_commit_sha_from_tag $START_TAG)
END_COMMIT_SHA=$(get_commit_sha_from_tag $END_TAG)

RESPONSE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/packbackbooks/code-challenge-devops/commits)

echo $RESPONSE | sed 's/\\n/ /g' | jq -r ".[] | .commit.message, .author.login, .sha" > lines.txt
# Reverse the order of these lines so that we see the final processed results
# in chronological order rather than in reverse chron
tac lines.txt > chron-order.txt && rm lines.txt

FOUND_START_COMMIT=0
FOUND_END_COMMIT=0
while read -r SHA; do
  read -r AUTHOR
  read -r MESSAGE

  if [[ $FOUND_START_COMMIT -eq 0 ]]
  then
    if [[ $SHA == $START_COMMIT_SHA ]]
    then
      FOUND_START_COMMIT=1
    else
      continue
    fi
  fi

  if [[ $FOUND_END_COMMIT -eq 0 ]]
  then
    if [[ $SHA == $END_COMMIT_SHA ]]
    then
      FOUND_END_COMMIT=1
    fi
  else
    # The end commit was already processed, so we can exit now
    exit
  fi

  IS_VALID_MESSAGE="FALSE"
  IS_MERGED_OR_REVERTED=$(merged_or_reverted $MESSAGE)
  IS_VALID_PREFIX=$(valid_commit_prefix "$MESSAGE")
  if [[ $IS_VALID_PREFIX == 1 ]] || [[ $IS_MERGED_OR_REVERTED == 1 ]]
  then
    IS_VALID_MESSAGE="TRUE"
  fi
  # Add $MESSAGE into the output below for debug purposes
  echo "$SHA $IS_VALID_MESSAGE $AUTHOR"

done<chron-order.txt

# Final cleanup
rm chron-order.txt
