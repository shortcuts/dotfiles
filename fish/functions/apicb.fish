function apicb
  cd /Users/clement.vannicatte/Documents/api-clients-automation/scripts && nvm use && yarn build:cli && NODE_NO_WARNINGS=1 node dist/scripts/cli/index.js $argv
end
