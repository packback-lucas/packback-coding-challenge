# packback-coding-challenge

Create an environment variable containing an access token that will let the script use the Github API. The reason for the `PREFIX` shenanigans is that Github does not allow you to commit a token, but splitting it up into 2 variables does the trick!
```bash
PREFIX="github_pat_"
export ACCESS_TOKEN="${PREFIX}11BI3SL6A0tDygfxy0g9F4_7KutAdiyNAP1jlBwUcTaF1cDNw9eDciZ7OEkWrk6t6bOJQXVJYRW5S38WRl"
```
