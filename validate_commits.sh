RESPONSE=$(curl -sL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/packbackbooks/code-challenge-devops/commits)

echo $RESPONSE | sed 's/\\n/ /g' | jq -r ".[] | .commit.message, .author.login, .sha"

#echo $LINES
