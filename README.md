[![Build Status](https://travis-ci.org/gobetti/CodeChallenge-iOS.svg)](https://travis-ci.org/gobetti/CodeChallenge-iOS) [![codecov.io](http://codecov.io/github/gobetti/CodeChallenge-iOS/coverage.svg?branch=master)](http://codecov.io/github/gobetti/CodeChallenge-iOS?branch=master)

# CodeChallenge-iOS
This is my attempt on a common code challenge applied by companies looking for iOS engineers. Usually they ask for an app that connects to a RESTful API to fetch a list of items, search through items and open a details page - the chosen API is what changes the most. This project uses TMDB.

## Manual build instructions
Please refer to the [.travis.yml](https://github.com/gobetti/CodeChallenge-iOS/blob/master/.travis.yml) file for commands to run before building.

Also, make sure to add your own API key to the `Constants.swift` file:

```
let api_key = "<your api key here>"
```
