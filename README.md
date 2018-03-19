# CodeChallenge-iOS
This is my attempt on a common code challenge applied by companies looking for iOS engineers. Usually they ask for an app that connects to a RESTful API to fetch a list of items, search through items and open a details page - the chosen API is what changes the most. This project uses TMDB.

## Build instructions
Run `git submodule update --init --recursive` in order to install the submodules.

Also, make sure to add your own API key to the `Constants.swift` file:

```
let api_key = "<your api key here>"
```

