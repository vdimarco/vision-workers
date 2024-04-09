#!/bin/bash
cleanup() {
  echo "Stopping the llm server server..."
  kill $process_pid
  wait $process_pid 2>/dev/null
  echo "Stopped"
}




cd llm_server
./entrypoint.sh &
process_pid=$!
cd ..


while true; do
  # Get the current tag
  local_tag=$(git describe --abbrev=0 --tags)
  # Fetch the latest updates
  git fetch
  # Get the latest remote tag
  remote_tag=$(git describe --tags $(git rev-list --topo-order --tags HEAD --max-count=1))

  # Check if an update is required
  if [[ $local_tag != $remote_tag ]]; then
    echo "Local repo is not up-to-date. Updating..."
    git reset --hard $remote_tag
    if [ $? -eq 0 ]; then
      echo "Updated local repo to latest version: $remote_tag"
      echo "Running the autoupdate steps..."
      # Kill the old process
      kill $process_pid
      wait $process_pid 2>/dev/null

      # Run any steps needed to update, other than getting the new code
      ./autoupdate_llm.sh

      # Restart the llm server
      cd llm_server
      ./entrypoint.sh &
      process_pid=$!
      cd ..
      echo "Finished running the autoupdate steps! Ready to go 😎"
    else
      echo "Error in updating"
    fi
  else
    echo "Repo is up-to-date."
  fi
  # Wait for a while before checking again
  sleep 10
done


cleanup()